// Built-in D7 receiver migration: relocate top-level instance methods into impl
// blocks. A top-level `fn Type.method(self: ...)` is "static by location" under
// D7; to become an implicit-self instance method it must move into an
// `impl Type:` (or `impl[Tp] Type[Args]:`) block, dropping `self` for the keyword
// form. Associated functions (`fn Type.make()` — no `self`) stay at top level.
//
// Sema selects top-level instance declarations and their finalized receiver
// modes. The compiler's Lexer is then used for token-accurate rewriting. Comments are
// whitespace to the lexer, so gaps between methods carry no tokens: a same-target
// run of methods (only comments/blanks between them) groups under one impl header,
// and their inter-method comments are re-indented into the block. A method whose
// type params are not all bound by its receiver (e.g. `Vec.map[T, U]` on `Vec[T]`)
// is SKIPPED and reported, never silently mis-moved.
//
//   with run tools/relocate_methods.w --report src/main.w     # whole-project proof
//   with run tools/relocate_methods.w --list src/main.w       # include every target
//   with run tools/relocate_methods.w --apply src/main.w      # rewrite selected files

use std.process
use AnalysisTypes
use compiler.Compilation
use Lexer
use Token

extern fn with_str_clone_ref(s: &str) -> str
extern fn with_fs_read_file(path: &str) -> str
extern fn with_fs_write_file(path: &str, data: &str) -> i32

// 0-based column of a byte offset (distance from the start of its line, 10 = '\n').
fn col_of(text: &str, offset: i32):
    var j = offset - 1
    while j >= 0 and (text.byte_at(j as i64) as i32) != 10:
        j = j - 1
    offset - (j + 1)

fn slice(text: &str, a: i32, b: i32): text.slice(a as i64, b as i64)

fn trim(s: &str):
    let m = s.len() as i32
    var a = 0
    while a < m and (s.byte_at(a as i64) as i32) == 32:
        a = a + 1
    var b = m
    while b > a and (s.byte_at((b - 1) as i64) as i32) == 32:
        b = b - 1
    slice(s, a, b)

// Names from a type-param inner text ("K: Ord, V" -> "K, V"): each top-level
// comma segment's identifier, stripped of its optional `: Bound`.
fn tparam_names(inner: &str):
    var parts: Vec[str] = Vec.new()
    let m = inner.len() as i32
    var seg_start = 0
    var depth = 0
    var i = 0
    while i <= m:
        let at_end = i == m
        let c = if at_end: 44 else: inner.byte_at(i as i64) as i32
        if c == 91:
            depth = depth + 1
        else if c == 93:
            depth = depth - 1
        else if c == 44 and depth == 0:
            var colon = seg_start
            while colon < i and (inner.byte_at(colon as i64) as i32) != 58:
                colon = colon + 1
            let nm = trim(slice(inner, seg_start, colon))
            if nm.len() as i32 > 0:
                parts.push(nm)
            seg_start = i + 1
        if at_end:
            break
        i = i + 1
    parts.join(", ")

// Prefix `pad` to every non-empty line of `text` (blank lines stay blank).
fn reindent(text: &str, pad: &str):
    var parts: Vec[str] = Vec.new()
    let m = text.len() as i32
    var line_start = 0
    var i = 0
    while i < m:
        if (text.byte_at(i as i64) as i32) == 10:
            if i > line_start:
                parts.push(with_str_clone_ref(pad))
                parts.push(slice(text, line_start, i))
            parts.push("\n")
            line_start = i + 1
        i = i + 1
    if m > line_start:
        parts.push(with_str_clone_ref(pad))
        parts.push(slice(text, line_start, m))
    parts.join("")

// Count top-level comma-separated segments in the bytes of a `[...]` group text.
fn count_args(inner: &str) -> i32:
    let m = inner.len() as i32
    if m == 0:
        return 0
    var depth = 0
    var segs = 1
    var i = 0
    while i < m:
        let c = inner.byte_at(i as i64) as i32
        if c == 91:            // [
            depth = depth + 1
        else if c == 93:       // ]
            depth = depth - 1
        else if c == 44 and depth == 0:   // , at top level
            segs = segs + 1
        i = i + 1
    segs

type RelocationFacts {
    paths: Vec[str],
    starts: Vec[i32],
    ends: Vec[i32],
    modes: Vec[i32],
    matched: Vec[i32],
}

fn local_source_path(path: &str) -> str:
    let embedded = "<embedded-std>/"
    if path.starts_with(embedded): "lib/" ++ slice(path, embedded.len() as i32, path.len() as i32) else: with_str_clone_ref(path)

fn compiler_relocation_facts(entry: &str) -> RelocationFacts:
    let result = compiler_analyze_file(entry, "select:kind=declaration")
    let facts = RelocationFacts { paths: Vec.new(), starts: Vec.new(), ends: Vec.new(), modes: Vec.new(), matched: Vec.new() }
    for i in 0..result.report.facts.len() as i32:
        let fact = result.report.facts.get(i as i64)
        if fact.kind != AnalysisFactKind.Declaration: continue
        if fact.flags & (AnalysisDeclarationFlag.TopLevelMethod as i32) == 0: continue
        let mode = fact.flags & 255
        if mode != AnalysisReceiverMode.Read as i32 and mode != AnalysisReceiverMode.Mut as i32 and mode != AnalysisReceiverMode.Move as i32: continue
        if fact.flags & (AnalysisDeclarationFlag.ExplicitReceiver as i32) == 0: continue
        facts.paths.push(local_source_path(fact.path))
        facts.starts.push(fact.start)
        facts.ends.push(fact.end)
        facts.modes.push(mode)
        facts.matched.push(0)
    facts

fn relocation_fact_at(facts: &RelocationFacts, path: &str, offset: i32) -> i32:
    for i in 0..facts.starts.len() as i32:
        if facts.paths.get(i as i64) == path and offset >= facts.starts.get(i as i64) and offset < facts.ends.get(i as i64): return i
    -1

fn relocate_file(path: &str, semantic: &RelocationFacts, apply: bool, list_methods: bool) -> i32:
    let text = with_fs_read_file(path)
    let tlen = text.len() as i32
    if tlen == 0:
        return 0
    var lexer = Lexer.init(text, 0)
    let tokens = lexer.tokenize()
    let n = tokens.len()

    var chunks: Vec[str] = Vec.new()
    var cursor = 0             // bytes emitted up to here
    var open_header = ""       // current open impl group header ("" = none)
    var count = 0
    var skipped = 0

    var i = 0
    while i < n:
        // Blank lines emit a NEWLINE token at column 0 — skip them; they are not
        // decls and must not reset an open impl group.
        if tokens.get_tag(i) == TokenKind.TK_NEWLINE:
            i = i + 1
            continue
        if col_of(text, tokens.get_start(i)) != 0:
            i = i + 1
            continue
        // i is a top-level decl start (column 0). Classify it.
        var fn_tok = i
        var vis_pub = false
        if tokens.get_tag(i) == TokenKind.TK_KW_PUB:
            vis_pub = true
            fn_tok = i + 1
        var reloc = false
        if fn_tok < n and tokens.get_tag(fn_tok) == TokenKind.TK_KW_FN:
            let ti = fn_tok + 1
            // Parser method names accept identifiers or keywords. Sema's exact
            // declaration span is the authority; here only the `Type . name`
            // token shape matters.
            if ti + 2 < n and tokens.get_tag(ti) == TokenKind.TK_IDENT and tokens.get_tag(ti + 1) == TokenKind.TK_DOT:
                reloc = true

        if not reloc:
            // Non-relocatable top-level decl → close any open impl group. Its text
            // stays at column 0 (emitted with the next gap or the tail).
            open_header = ""
            i = i + 1
            continue

        // ---- extract the method ----
        let decl_start = if vis_pub: tokens.get_start(i) else: tokens.get_start(fn_tok)
        let fn_pos = tokens.get_start(fn_tok)
        let type_idx = fn_tok + 1
        let type_start = tokens.get_start(type_idx)
        let type_name = slice(text, type_start, tokens.get_end(type_idx))
        let name_start = tokens.get_start(type_idx + 2)

        // optional method type params `[...]`, then `(`
        var k = type_idx + 3
        var has_tp = false
        var tp_open = 0
        var tp_inner_a = 0
        var tp_inner_b = 0
        if k < n and tokens.get_tag(k) == TokenKind.TK_L_BRACKET:
            has_tp = true
            tp_open = tokens.get_start(k)
            tp_inner_a = tokens.get_end(k)
            var bd = 0
            while k < n:
                let bt = tokens.get_tag(k)
                if bt == TokenKind.TK_L_BRACKET:
                    bd = bd + 1
                else if bt == TokenKind.TK_R_BRACKET:
                    bd = bd - 1
                    if bd == 0:
                        tp_inner_b = tokens.get_start(k)
                        k = k + 1
                        break
                k = k + 1
        if k >= n or tokens.get_tag(k) != TokenKind.TK_L_PAREN:
            open_header = ""
            i = i + 1
            continue
        let paren_pos = tokens.get_start(k)
        let tp_start = if has_tp: tp_open else: paren_pos
        let tp_end = paren_pos

        // first param must be `[mut|move] self`
        var fp = k + 1
        var source_mode = AnalysisReceiverMode.Read as i32
        var param_start = tokens.get_start(fp)
        var self_tok = fp
        if fp < n and tokens.get_tag(fp) == TokenKind.TK_KW_MUT:
            source_mode = AnalysisReceiverMode.Mut as i32
            self_tok = fp + 1
        else if fp < n and tokens.get_tag(fp) == TokenKind.TK_KW_MOVE:
            source_mode = AnalysisReceiverMode.Move as i32
            self_tok = fp + 1
        if self_tok >= n or tokens.get_tag(self_tok) != TokenKind.TK_IDENT or slice(text, tokens.get_start(self_tok), tokens.get_end(self_tok)) != "self":
            open_header = ""
            i = i + 1
            continue

        let semantic_index = relocation_fact_at(semantic, path, fn_pos)
        if semantic_index < 0:
            skipped = skipped + 1
            open_header = ""
            i = i + 1
            continue
        if semantic.matched.get(semantic_index as i64) != 0:
            print(f"error: {path}: duplicate relocation match at byte {fn_pos}")
            return -1
        semantic.matched.set_i32(semantic_index as i64, 1)
        let mode = semantic.modes.get(semantic_index as i64)
        if source_mode != mode:
            print(f"error: {path}: source/compiler receiver mode mismatch at byte {fn_pos}")
            return -1
        let mode_kw = if mode == AnalysisReceiverMode.Mut as i32: "mut " else if mode == AnalysisReceiverMode.Move as i32: "move " else: ""

        // receiver type: after `self :` to top-level `,`/`)`
        var rt = self_tok + 1
        if rt < n and tokens.get_tag(rt) == TokenKind.TK_COLON:
            rt = rt + 1
        let recv_start = tokens.get_start(rt)
        var depth = 0
        var q = rt
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
        var recv_type = slice(text, recv_start, tokens.get_start(q))
        // strip a leading `&` (borrow) and spaces
        var rti = 0
        let rlen = recv_type.len() as i32
        while rti < rlen and (recv_type.byte_at(rti as i64) as i32) == 38:   // &
            rti = rti + 1
        while rti < rlen and (recv_type.byte_at(rti as i64) as i32) == 32:   // space
            rti = rti + 1
        // Target type = the DOTTED type name + the receiver's generic args `[...]`
        // if any. The receiver base is often spelled `Self` (an alias for the
        // dotted type), so the base MUST come from the dotted name, never the
        // receiver spelling — else every `self: &Self` method yields `impl Self:`.
        var target = with_str_clone_ref(type_name)
        var bpos = rti
        while bpos < rlen and (recv_type.byte_at(bpos as i64) as i32) != 91:   // '['
            bpos = bpos + 1
        if bpos < rlen:
            target = type_name ++ slice(recv_type, bpos, rlen)   // explicit `Type[Args]`
        else if has_tp:
            // receiver is `Self` (no explicit args) but the method is generic —
            // the target args are the method's type-param names.
            target = type_name ++ "[" ++ tparam_names(slice(text, tp_inner_a, tp_inner_b)) ++ "]"

        // self param deletion end
        var self_del_end = tokens.get_start(q)
        if q < n and tokens.get_tag(q) == TokenKind.TK_COMMA:
            self_del_end = tokens.get_end(q)
            while self_del_end < tlen and (text.byte_at(self_del_end as i64) as i32) == 32:
                self_del_end = self_del_end + 1

        // method extent: up to the next column-0 token, skipping trailing NEWLINE
        // tokens so body_end lands just after the method's last content line.
        var j = fn_tok + 1
        while j < n and (tokens.get_tag(j) == TokenKind.TK_NEWLINE or col_of(text, tokens.get_start(j)) != 0):
            j = j + 1
        var last = j - 1
        while last > fn_tok and tokens.get_tag(last) == TokenKind.TK_NEWLINE:
            last = last - 1
        var body_end = tokens.get_end(last)
        while body_end < tlen and (text.byte_at(body_end as i64) as i32) != 10:
            body_end = body_end + 1
        if body_end < tlen:
            body_end = body_end + 1

        // build the impl header. Method type params must all be bound by the
        // receiver: require count(tparams) == count(target args), else skip+report.
        var tp_decl = ""
        if has_tp:
            tp_decl = slice(text, tp_open, tp_inner_b + 1)   // `[K: Ord, V]`
        var ok = true
        if has_tp:
            let tp_inner = slice(text, tp_inner_a, tp_inner_b)
            // target args: inside the target's own `[...]`
            let tl = target.len() as i32
            var ta = 0
            while ta < tl and (target.byte_at(ta as i64) as i32) != 91:  // find [
                ta = ta + 1
            if ta >= tl:
                ok = false
            else:
                var tb = tl - 1
                while tb > ta and (target.byte_at(tb as i64) as i32) != 93:  // find ]
                    tb = tb - 1
                let target_args = slice(target, ta + 1, tb)
                if count_args(tp_inner) != count_args(target_args):
                    ok = false
        // A legacy top-level `Type.method` was globally inherent regardless of
        // its source file. Preserve that semantic identity with `impl`; `extend`
        // is module-scoped and would silently narrow method visibility.
        let header = f"impl{tp_decl} {target}:"

        if not apply:
            if list_methods:
                let flag = if ok: "" else: "  [SKIP: complex type params]"
                print(f"  {type_name}.{slice(text, name_start, tokens.get_end(type_idx + 2))}  {header}{flag}")
            if ok:
                count = count + 1
            else:
                skipped = skipped + 1
            i = j
            continue

        if not ok:
            skipped = skipped + 1
            open_header = ""     // leave this method at top level; it ends any group
            i = j
            continue

        // ---- emit ----
        let gap = slice(text, cursor, decl_start)
        if open_header == header:
            chunks.push(reindent(gap, "    "))     // inter-method comments go inside
        else:
            chunks.push(gap)                        // leading comments at column 0
            chunks.push(with_str_clone_ref(header))
            chunks.push("\n")
            open_header = header

        // transformed method: pub? + mode + `fn ` + name + `(` + params-after-self + body
        var mparts: Vec[str] = Vec.new()
        mparts.push(slice(text, decl_start, fn_pos))   // `pub ` or ``
        mparts.push(mode_kw)                           // `mut `/`move `/``
        mparts.push(slice(text, fn_pos, type_start))   // `fn `
        mparts.push(slice(text, name_start, tp_start)) // method name
        mparts.push(slice(text, tp_end, param_start))  // `(`
        mparts.push(slice(text, self_del_end, body_end))  // rest (params, ret, body)
        chunks.push(reindent(mparts.join(""), "    "))

        cursor = body_end
        count = count + 1
        i = j

    for fi in 0..semantic.matched.len() as i32:
        if semantic.paths.get(fi as i64) == path and semantic.matched.get(fi as i64) == 0:
            print(f"error: {path}: compiler-selected declaration at byte {semantic.starts.get(fi as i64)} was not structurally matched")
            return -1

    if not apply:
        if count > 0 or skipped > 0:
            print(f"{path}: {count} relocatable, {skipped} skipped")
        if skipped > 0: return -1
        return count

    if skipped > 0:
        print(f"error: {path}: {skipped} methods have unbound/complex type parameters; file left unchanged")
        return -1
    if count == 0:
        return 0
    chunks.push(slice(text, cursor, tlen))    // tail
    if with_fs_write_file(path, chunks.join("")) != 0:
        print("error: failed to write " ++ path)
        return -1
    print(f"{path}: relocated {count}")
    count

fn path_excluded(path: &str, excludes: &Vec[str]) -> bool:
    for i in 0..excludes.len() as i32:
        let excluded = excludes.get(i as i64)
        if path == excluded or path.starts_with(excluded ++ "/"): return true
    false

fn unique_relocation_paths(facts: &RelocationFacts, excludes: &Vec[str]) -> Vec[str]:
    let paths: Vec[str] = Vec.new()
    for i in 0..facts.paths.len() as i32:
        let path = facts.paths.get(i as i64)
        if path_excluded(path, excludes): continue
        var seen = false
        for pi in 0..paths.len() as i32:
            if paths.get(pi as i64) == path:
                seen = true
                break
        if not seen: paths.push(with_str_clone_ref(path))
    paths

fn count_selected(facts: &RelocationFacts, excludes: &Vec[str]) -> i32:
    var count = 0
    for i in 0..facts.paths.len() as i32:
        if not path_excluded(facts.paths.get(i as i64), excludes): count = count + 1
    count

fn verify_all_matched(facts: &RelocationFacts, excludes: &Vec[str]) -> bool:
    for i in 0..facts.matched.len() as i32:
        if path_excluded(facts.paths.get(i as i64), excludes): continue
        if facts.matched.get(i as i64) == 0:
            print(f"error: {facts.paths.get(i as i64)}: compiler-selected declaration at byte {facts.starts.get(i as i64)} was not processed")
            return false
    true

fn reset_matches(facts: &RelocationFacts):
    for i in 0..facts.matched.len() as i32: facts.matched.set_i32(i as i64, 0)

pub fn run_receiver_migration -> i32:
    let argv = args()
    if argv.len() < 2:
        print("usage: relocate_methods [--report|--list|--apply] [--exclude path ...] <entry.w>")
        exit_code(1)
    var apply = false
    var list_methods = false
    let excludes: Vec[str] = Vec.new()
    var entry = ""
    var arg = 2
    while arg < argv.len() as i32:
        if argv.get(arg as i64) == "--apply":
            apply = true
        else if argv.get(arg as i64) == "--report":
            apply = false
        else if argv.get(arg as i64) == "--list":
            list_methods = true
        else if argv.get(arg as i64) == "--exclude":
            if arg + 1 >= argv.len() as i32:
                print("error: --exclude requires a file path")
                exit_code(1)
            arg = arg + 1
            excludes.push(with_str_clone_ref(argv.get(arg as i64)))
        else:
            if entry.len() > 0:
                print("error: exactly one semantic entry file is required")
                exit_code(1)
            entry = with_str_clone_ref(argv.get(arg as i64))
        arg = arg + 1
    if entry.len() == 0:
        print("error: no semantic entry file supplied")
        exit_code(1)
    let facts = compiler_relocation_facts(entry)
    let paths = unique_relocation_paths(&facts, &excludes)
    let selected = count_selected(&facts, &excludes)
    // Always complete a no-write structural preflight over the whole semantic
    // selection before the first file can be changed.
    var preflight = 0
    for i in 0..paths.len() as i32:
        let changed = relocate_file(paths.get(i as i64), &facts, false, list_methods)
        if changed < 0: exit_code(1)
        preflight = preflight + changed
    if not verify_all_matched(&facts, &excludes): exit_code(1)
    if preflight != selected:
        print(f"error: compiler selected {selected} methods but the rewriter matched {preflight}")
        exit_code(1)
    if not apply:
        print(f"receiver-relocation: selected={selected} matched={preflight} files={paths.len() as i32} mode=report")
        return 0
    reset_matches(&facts)
    var changed_total = 0
    for i in 0..paths.len() as i32:
        let changed = relocate_file(paths.get(i as i64), &facts, true, false)
        if changed < 0: exit_code(1)
        changed_total = changed_total + changed
    if not verify_all_matched(&facts, &excludes) or changed_total != selected:
        print(f"error: apply phase changed {changed_total} of {selected} selected methods")
        exit_code(1)
    print(f"receiver-relocation: selected={selected} matched={preflight} changed={changed_total} files={paths.len() as i32} mode=apply")
    0
