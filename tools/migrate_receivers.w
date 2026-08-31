// D7 eliminate-self syntax migration driven by live compiler declaration facts.
//
// Rewrites in-place receiver methods declared inside impl/extend/trait blocks:
//   fn get(self: &Self) -> T    =>   fn get() -> T
//   fn set(mut self: Self, v)   =>   mut fn set(v)
//   fn take(move self: Self)    =>   move fn take()
// `self` and its type are dropped; the mode becomes a keyword before `fn`.
//
// SKIPPED (need relocation into an impl block, not yet handled): top-level dotted
// methods `fn Type.method(self: T)` — recognised by the `.` after the fn name.
// Associated / free functions (no `self` first param) are left untouched. A plain
// read-borrow `self: &Self` is migrated ONLY inside an inherent `impl`/`extend`
// (where D7 P2 synthesizes it); in a trait def or trait impl (`impl T for U`) the
// trait dictates the receiver, so read borrows there keep the explicit `self`.
// `mut fn`/`move fn` synthesize regardless, so those migrate in any block.
//
// Sema selects valid declarations and receiver modes. The Lexer is used only to
// locate exact byte ranges inside those compiler-proven declaration spans.
//
//   with run tools/migrate_receivers.w lib/std/rc.w lib/std/box.w ...
//   with run tools/migrate_receivers.w --exclude test/negative.w test examples

use std.process
use AnalysisTypes
use compiler.Compilation
use Lexer
use Token

extern fn with_fs_read_file(path: &str) -> str
extern fn with_fs_list_files(path: &str) -> str
extern fn with_fs_write_file(path: &str, data: &str) -> i32

fn slice(text: &str, start: i32, end: i32): text.slice(start as i64, end as i64)

type ReceiverDeclFacts {
    starts: Vec[i32],
    ends: Vec[i32],
    modes: Vec[i32],
    flags: Vec[i32],
}

fn compiler_receiver_decls(path: &str) -> ReceiverDeclFacts:
    let result = compiler_analyze_file(path, "select:kind=declaration")
    let facts = ReceiverDeclFacts { starts: Vec.new(), ends: Vec.new(), modes: Vec.new(), flags: Vec.new() }
    for i in 0..result.report.facts.len() as i32:
        let fact = result.report.facts.get(i as i64)
        if fact.kind != AnalysisFactKind.Declaration or fact.path != path: continue
        let mode = fact.flags & 255
        if mode != AnalysisReceiverMode.Read as i32 and mode != AnalysisReceiverMode.Mut as i32 and mode != AnalysisReceiverMode.Move as i32: continue
        if fact.flags & (AnalysisDeclarationFlag.InImpl as i32) == 0: continue
        if fact.flags & (AnalysisDeclarationFlag.ExplicitReceiver as i32) == 0: continue
        facts.starts.push(fact.start)
        facts.ends.push(fact.end)
        facts.modes.push(mode)
        facts.flags.push(fact.flags)
    facts

fn receiver_fact_at(facts: &ReceiverDeclFacts, offset: i32) -> i32:
    for i in 0..facts.starts.len() as i32:
        if offset >= facts.starts.get(i as i64) and offset < facts.ends.get(i as i64): return i
    -1

fn migrate_file(path: &str) -> i32:
    let text = unsafe { with_fs_read_file(path) }
    let tlen = text.len() as i32
    if tlen == 0:
        return 0
    let declarations = compiler_receiver_decls(path)
    var lexer = Lexer.init(text, 0)
    let tokens = lexer.tokenize()
    let n = tokens.len()

    // Edits as (start, end, replacement) byte-offset splices, in ascending order.
    var starts: Vec[i32] = Vec.new()
    var ends: Vec[i32] = Vec.new()
    var repls: Vec[str] = Vec.new()

    var failures = 0
    var i = 0
    while i < n:
        let tag_i = tokens.get_tag(i)
        if tag_i != TokenKind.TK_KW_FN:
            i = i + 1
            continue
        let fn_pos = tokens.get_start(i)
        let name_idx = i + 1
        if name_idx >= n or tokens.get_tag(name_idx) != TokenKind.TK_IDENT:
            i = i + 1
            continue
        // `fn Type.method` (dotted) → top level, needs relocation → skip.
        if name_idx + 1 < n and tokens.get_tag(name_idx + 1) == TokenKind.TK_DOT:
            i = i + 1
            continue
        // Skip optional method type params `[T, ...]`.
        var k = name_idx + 1
        if k < n and tokens.get_tag(k) == TokenKind.TK_L_BRACKET:
            var bdepth = 0
            while k < n:
                let bt = tokens.get_tag(k)
                if bt == TokenKind.TK_L_BRACKET:
                    bdepth = bdepth + 1
                else if bt == TokenKind.TK_R_BRACKET:
                    bdepth = bdepth - 1
                    if bdepth == 0:
                        k = k + 1
                        break
                k = k + 1
        if k >= n or tokens.get_tag(k) != TokenKind.TK_L_PAREN:
            i = i + 1
            continue
        // First parameter: optional mut/move, then must be `self`.
        var p = k + 1
        var mode = 0
        if p < n and tokens.get_tag(p) == TokenKind.TK_KW_MUT:
            mode = 2
            p = p + 1
        else if p < n and tokens.get_tag(p) == TokenKind.TK_KW_MOVE:
            mode = 3
            p = p + 1
        if p >= n or tokens.get_tag(p) != TokenKind.TK_IDENT:
            i = i + 1
            continue
        if text.slice(tokens.get_start(p) as i64, tokens.get_end(p) as i64) != "self":
            i = i + 1
            continue
        let fact_index = receiver_fact_at(&declarations, fn_pos)
        if fact_index < 0:
            i = i + 1
            continue
        let declared_mode = declarations.modes.get(fact_index as i64)
        // #727: trait-IMPL read borrows migrate too — synthesis is
        // trait-contract-driven (pinned by
        // behav_trait_impl_keyword_receivers, incl. the body-never-touches-
        // self case), so the D7-era conservative trait-impl skip is retired.
        // Trait DECLARATION read contracts stay explicit (the D7 carve-out:
        // associated contracts must remain spellable).
        let trait_decl = declarations.flags.get(fact_index as i64) & (AnalysisDeclarationFlag.TraitDeclaration as i32) != 0
        if declared_mode == AnalysisReceiverMode.Read as i32 and trait_decl:
            i = i + 1
            continue
        let syntax_mode = if mode == 2: AnalysisReceiverMode.Mut as i32 else if mode == 3: AnalysisReceiverMode.Move as i32 else: AnalysisReceiverMode.Read as i32
        if syntax_mode != declared_mode:
            print(f"error: {path}: receiver syntax/compiler mode mismatch at byte {fn_pos}")
            failures = failures + 1
            i = i + 1
            continue

        // Found a receiver `self`. Delete range = its first token .. end of param.
        let param_start_idx = if mode == 0: p else: p - 1
        let del_start = tokens.get_start(param_start_idx)
        var q = p + 1
        var depth = 0
        while q < n:
            let t = tokens.get_tag(q)
            if t == TokenKind.TK_L_PAREN or t == TokenKind.TK_L_BRACKET:
                depth = depth + 1
            else if t == TokenKind.TK_R_BRACKET:
                depth = depth - 1
            else if t == TokenKind.TK_R_PAREN:
                if depth == 0:
                    break
                depth = depth - 1
            else if t == TokenKind.TK_COMMA and depth == 0:
                break
            q = q + 1
        var del_end = tokens.get_start(q)
        if q < n and tokens.get_tag(q) == TokenKind.TK_COMMA:
            del_end = tokens.get_end(q)
        // Eat trailing spaces so `self: T, v` collapses to `v`, not ` v`.
        while del_end < tlen and (text.byte_at(del_end as i64) as i32) == 32:
            del_end = del_end + 1

        if mode == 2:
            starts.push(fn_pos)
            ends.push(fn_pos)
            repls.push("mut ")
        else if mode == 3:
            starts.push(fn_pos)
            ends.push(fn_pos)
            repls.push("move ")
        starts.push(del_start)
        ends.push(del_end)
        repls.push("")
        i = q

    if failures != 0:
        print(f"error: {path}: {failures} receiver declarations failed semantic preflight; file left unchanged")
        return -1
    let m = starts.len() as i32
    if m == 0:
        return 0
    // Edits are ascending (fn_pos < del_start; methods top-to-bottom): apply L→R.
    var result = ""
    var prev = 0
    var methods = 0
    for e in 0..m:
        let s = starts.get(e as i64)
        let en = ends.get(e as i64)
        let r = repls.get(e as i64)
        if r.len() == 0:
            methods = methods + 1
        result = result ++ text.slice(prev as i64, s as i64) ++ r
        prev = en
    result = result ++ text.slice(prev as i64, text.len() as i64)
    let _ = unsafe { with_fs_write_file(path, result) }
    methods

fn path_excluded(path: &str, excludes: &Vec[str]) -> bool:
    for i in 0..excludes.len() as i32:
        if path == excludes.get(i as i64): return true
    false

fn migrate_path(path: &str, excludes: &Vec[str]) -> i32:
    if path_excluded(path, excludes): return 0
    if path.ends_with(".w"):
        let changed = migrate_file(path)
        if changed > 0: print(f"migrated {path}: {changed} receiver methods")
        return changed
    let listing = unsafe { with_fs_list_files(path) }
    var total = 0
    var start = 0
    for i in 0..listing.len() as i32 + 1:
        if i != listing.len() as i32 and listing.byte_at(i as i64) as i32 != 10: continue
        if i > start:
            let file = slice(listing, start, i)
            if file.ends_with(".w") and not path_excluded(file, excludes):
                let changed = migrate_file(file)
                if changed < 0: return -1
                if changed > 0: print(f"migrated {file}: {changed} receiver methods")
                total = total + changed
        start = i + 1
    total

fn main:
    let argv = args()
    if argv.len() < 2:
        print("usage: migrate_receivers [--exclude file.w ...] <file-or-dir> [file-or-dir ...]")
        exit_code(1)
    let excludes: Vec[str] = Vec.new()
    let paths: Vec[str] = Vec.new()
    var arg = 1
    while arg < argv.len() as i32:
        if argv.get(arg as i64) == "--exclude":
            if arg + 1 >= argv.len() as i32:
                print("error: --exclude requires a file path")
                exit_code(1)
            arg = arg + 1
            excludes.push(argv.get(arg as i64).clone())
        else:
            paths.push(argv.get(arg as i64).clone())
        arg = arg + 1
    if paths.len() == 0:
        print("error: no migration paths supplied")
        exit_code(1)
    var total = 0
    for i in 0..paths.len() as i32:
        let changed = migrate_path(paths.get(i as i64), &excludes)
        if changed < 0: exit_code(1)
        total = total + changed
    print(f"total: {total} receiver methods migrated")
