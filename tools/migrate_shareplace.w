// D5-supersession migration: read-only free parameters declared as plain `T`
// that the (overruled) effects classifier passes as share-place become
// declared `&T` borrows, so the signature states the ownership mode and the
// classifier's non-receiver inference can be deleted (docs/decisions.md D5,
// Eric's ruling: D5 is overruled).
//
// Selection comes from live compiler facts, never source scanning:
//   - Parameter facts (stage=sema) with value_ref_abi set (flags bit0),
//   - excluding receivers (index 0 of a sig that has a Receiver fact),
//   - excluding write/consume/escape-value effects (those 7 are hand-fixed:
//     they mutate the caller's place and need take-and-return or a receiver).
// The Lexer locates exact byte offsets inside the declaration's fact span;
// the edit is a single `&` inserted before the parameter's type. Any shape
// the walker cannot prove out fails loudly and nothing is written.
//
//   with run tools/migrate_shareplace.w src/main.w            # dry run (report)
//   with run tools/migrate_shareplace.w src/main.w --apply    # write files

use std.process
use AnalysisTypes
use compiler.Compilation
use Lexer
use Token

extern fn with_fs_read_file(path: &str) -> str
extern fn with_fs_write_file(path: &str, data: &str) -> i32
extern fn with_str_clone_ref(s: &str) -> str

fn owned_text(s: &str): unsafe { with_str_clone_ref(s) }

// Mirrors of Sema effect bits (private there; layout is spec-stable).
const MIG_EFF_WRITE: i32 = 2
const MIG_EFF_CONSUME: i32 = 4
const MIG_EFF_ESCAPE_VALUE: i32 = 8

type ShareTarget {
    path: str,
    fn_name: str,
    sig_index: i32,
    has_receiver: bool,
}

type DeclSpan {
    path: str,
    name: str,
    start: i32,
    end: i32,
}

type CollectResult {
    targets: Vec[ShareTarget],
    decls: Vec[DeclSpan],
}

fn collect_targets(entry: &str) -> CollectResult:
    let result = compiler_analyze_file(entry, "facts")
    var receiver_sigs: Vec[i32] = Vec.new()
    for i in 0..result.report.facts.len() as i32:
        let fact = &result.report.facts[i]
        if fact.kind == AnalysisFactKind.Receiver:
            receiver_sigs.push(fact.parent)
    var targets: Vec[ShareTarget] = Vec.new()
    var decls: Vec[DeclSpan] = Vec.new()
    for i in 0..result.report.facts.len() as i32:
        let fact = &result.report.facts[i]
        if fact.kind == AnalysisFactKind.Declaration:
            var decl_path = owned_text(fact.path)
            if decl_path.starts_with("<embedded-std>/std/"):
                decl_path = "lib/std/" ++ decl_path.slice(19, decl_path.len() as i64)
            decls.push(DeclSpan { path: move decl_path, name: owned_text(fact.name), start: fact.start, end: fact.end })
    for i in 0..result.report.facts.len() as i32:
        let fact = &result.report.facts[i]
        if fact.kind != AnalysisFactKind.Parameter: continue
        if fact.stage != AnalysisStage.Sema: continue
        // Post-D5 the classifier is gone, so value_ref_abi no longer marks
        // candidates. Select §3.8 conformance targets directly: an OWNED
        // (non-Copy, non-reference) parameter whose final effect only reads
        // observes its value and should declare the borrow. eff=[read] can
        // lie for bodies that move out through the param (#730) — always
        // sweep the apply diff for `self.x = p.f` / `.set(p)` / `.push(p)` /
        // `.insert(p)` shapes before trusting a run.
        if not fact.detail.starts_with("owned"): continue
        if fact.effects & (MIG_EFF_WRITE | MIG_EFF_CONSUME | MIG_EFF_ESCAPE_VALUE) != 0: continue
        var is_recv_sig = false
        for r in receiver_sigs:
            if r == fact.parent: is_recv_sig = true
        if is_recv_sig and fact.index == 0: continue
        // Embedded stdlib facts carry their embedded identity; the on-disk
        // source they were embedded from is lib/std/...
        var src_path = owned_text(fact.path)
        if src_path.starts_with("<embedded-std>/std/"):
            src_path = "lib/std/" ++ src_path.slice(19, src_path.len() as i64)
        // Extern signatures have parameter facts but no ordinary declaration
        // fact. They are ABI contracts, never source-migration candidates.
        let decl_name = base_name(fact.name)
        if decl_for(&decls, src_path, decl_name) < 0:
            continue
        targets.push(ShareTarget { path: move src_path, fn_name: owned_text(fact.name), sig_index: fact.index, has_receiver: is_recv_sig })
    CollectResult { targets, decls }

fn find_dollar(name: &str) -> i32:
    for i in 0..name.len() as i32:
        if name[i] as i32 == 36: return i
    -1

fn base_name(name: &str) -> str:
    // Strip any specialization suffix so mono sigs join to their template decl.
    let cut = find_dollar(name)
    if cut >= 0: return owned_text(name.slice(0, cut as i64))
    owned_text(name)

fn decl_for(decls: &Vec[DeclSpan], path: &str, name: &str) -> i32:
    for i in 0..decls.len() as i32:
        let d = &decls[i]
        if d.path == path and d.name == name: return i
    -1

fn main:
    let argv = args()
    if argv.len() < 2:
        print("usage: with run tools/migrate_shareplace.w <entry.w> [--apply]")
        exit_code(1)
    let entry = argv.get(1)
    let apply = argv.len() as i32 >= 3 and argv.get(2) == "--apply"
    let collected = collect_targets(entry)
    let targets = collected.targets
    let decls = collected.decls
    print(f"targets: {targets.len() as i32} share-place free parameters")

    // (path, insert-offset) edits, deduped across specializations.
    var edit_paths: Vec[str] = Vec.new()
    var edit_offsets: Vec[i32] = Vec.new()
    var failures = 0
    var fi = 0
    while fi < targets.len() as i32:
        let t = &targets[fi]
        fi = fi + 1
        let name = base_name(t.fn_name)
        let di = decl_for(&decls, t.path, name)
        if di < 0:
            print(f"error: no declaration fact for {name} in {t.path}")
            failures = failures + 1
            continue
        let d = &decls[di]
        let decl_start = d.start
        let text = unsafe { with_fs_read_file(t.path) }
        if text.len() == 0:
            print(f"error: cannot read {t.path}")
            failures = failures + 1
            continue
        var lexer = Lexer.init(text, 0)
        let tokens = lexer.tokenize()
        let n = tokens.len()

        // Find the `fn` token at the declaration span, skip name + generics.
        var i = 0
        while i < n and tokens.get_start(i) < decl_start: i = i + 1
        // Declarations span from their leading keywords: any mix of
        // pub / unsafe / mut / move precedes `fn`.
        while i < n and (tokens.get_tag(i) == TokenKind.TK_KW_MUT or tokens.get_tag(i) == TokenKind.TK_KW_MOVE or tokens.get_tag(i) == TokenKind.TK_KW_PUB or tokens.get_tag(i) == TokenKind.TK_KW_UNSAFE): i = i + 1
        if i >= n or tokens.get_tag(i) != TokenKind.TK_KW_FN:
            print(f"error: {name}: no fn token at declaration start byte {decl_start} in {t.path}")
            failures = failures + 1
            continue
        var k = i + 1
        while k < n and (tokens.get_tag(k) == TokenKind.TK_IDENT or tokens.get_tag(k) == TokenKind.TK_DOT): k = k + 1
        if k < n and tokens.get_tag(k) == TokenKind.TK_L_BRACKET:
            var bdepth = 0
            while k < n:
                let bt = tokens.get_tag(k)
                if bt == TokenKind.TK_L_BRACKET: bdepth = bdepth + 1
                else if bt == TokenKind.TK_R_BRACKET:
                    bdepth = bdepth - 1
                    if bdepth == 0:
                        k = k + 1
                        break
                k = k + 1
        if k >= n or tokens.get_tag(k) != TokenKind.TK_L_PAREN:
            print(f"error: {name}: no parameter list at byte {decl_start} in {t.path}")
            failures = failures + 1
            continue

        // Source position: sig index, minus one when the receiver is
        // synthesized (no `self` token in the source parameter list).
        var src_pos = t.sig_index
        if t.has_receiver:
            var p = k + 1
            if p < n and (tokens.get_tag(p) == TokenKind.TK_KW_MUT or tokens.get_tag(p) == TokenKind.TK_KW_MOVE): p = p + 1
            var explicit_self = false
            if p < n and tokens.get_tag(p) == TokenKind.TK_IDENT:
                if text.slice(tokens.get_start(p) as i64, tokens.get_end(p) as i64) == "self": explicit_self = true
            if not explicit_self: src_pos = src_pos - 1

        // Walk top-level commas to source parameter src_pos.
        var pos = 0
        var q = k + 1
        var depth = 0
        var walk_ok = true
        while q < n and pos < src_pos:
            let tt = tokens.get_tag(q)
            if tt == TokenKind.TK_L_PAREN or tt == TokenKind.TK_L_BRACKET: depth = depth + 1
            else if tt == TokenKind.TK_R_PAREN or tt == TokenKind.TK_R_BRACKET:
                if depth == 0:
                    print(f"error: {name}: parameter {src_pos} beyond parameter list in {t.path}")
                    walk_ok = false
                    break
                depth = depth - 1
            else if tt == TokenKind.TK_COMMA and depth == 0: pos = pos + 1
            q = q + 1
        if not walk_ok:
            failures = failures + 1
            continue

        // At parameter start: optional mut, IDENT, `:`, then the type.
        if q < n and tokens.get_tag(q) == TokenKind.TK_KW_MUT: q = q + 1
        if q >= n or tokens.get_tag(q) != TokenKind.TK_IDENT:
            print(f"error: {name}: parameter {src_pos} does not start with an identifier in {t.path}")
            failures = failures + 1
            continue
        q = q + 1
        if q >= n or tokens.get_tag(q) != TokenKind.TK_COLON:
            print(f"error: {name}: parameter {src_pos} has no `:` type annotation in {t.path}")
            failures = failures + 1
            continue
        q = q + 1
        if q >= n:
            print(f"error: {name}: parameter {src_pos} has no type tokens in {t.path}")
            failures = failures + 1
            continue
        let type_tag = tokens.get_tag(q)
        if type_tag == TokenKind.TK_AMPERSAND or type_tag == TokenKind.TK_STAR:
            // Already reference/pointer spelled — the classifier should not
            // have marked it; refuse rather than double-annotate.
            print(f"error: {name}: parameter {src_pos} already reference-typed in {t.path}")
            failures = failures + 1
            continue
        let off = tokens.get_start(q)

        var dup = false
        for e in 0..edit_paths.len() as i32:
            if edit_paths[e] == t.path and edit_offsets[e] == off: dup = true
        if dup: continue
        print(f"target: {t.path}:{name} parameter {t.sig_index}")
        edit_paths.push(owned_text(t.path))
        edit_offsets.push(off)

    if failures != 0:
        print(f"error: {failures} parameters failed fact/lexical preflight; nothing written")
        exit_code(1)

    // Apply per file, edits sorted ascending.
    var files: Vec[str] = Vec.new()
    for e in 0..edit_paths.len() as i32:
        let p = edit_paths[e]
        var seen = false
        for f in files:
            if f == p: seen = true
        if not seen: files.push(owned_text(p))
    var total = 0
    for f in files:
        var offs: Vec[i32] = Vec.new()
        for e in 0..edit_paths.len() as i32:
            if edit_paths[e] == f: offs.push(edit_offsets[e])
        var sorted: Vec[i32] = Vec.new()
        while sorted.len() < offs.len():
            var best = 2147483647
            for o in offs:
                var used = false
                for s in sorted:
                    if s == o: used = true
                if not used and o < best: best = o
            sorted.push(best)
        offs = sorted
        if apply:
            let text = unsafe { with_fs_read_file(f) }
            var out = ""
            var prev = 0
            for o in offs:
                out = out ++ text.slice(prev as i64, o as i64) ++ "&"
                prev = o
            out = out ++ text.slice(prev as i64, text.len() as i64)
            let rc = unsafe { with_fs_write_file(f, out) }
            if rc != 0:
                print(f"error: write failed for {f}")
                exit_code(1)
        print(f"{f}: {offs.len() as i32} parameters")
        total = total + offs.len() as i32
    print(f"total: {total} parameters " ++ (if apply: "annotated" else: "to annotate (dry run)"))
