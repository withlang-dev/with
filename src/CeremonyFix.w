// `with fix-ceremony` — remove ceremony the compiler can prove unnecessary
// (#3061; CLAUDE.md "Ceremony is a design defect"). The census counts; this
// rewrites. Every rewrite rests on a fact Sema recorded while it checked the
// program (Sema.w `ceremony_*`), never on the text's shape:
//
//   annotation   `let x: T = e` where `e`'s type is `T` and the initializer
//                is typed without the annotation's demand: `: T` goes.
//   var          a `var` whose binding is never assigned again and never
//                passed to a `mut` parameter (§3.8a): `let`.
//
//   with fix-ceremony --report <entry.w>     # every rewrite, by file and line
//   with fix-ceremony --apply  <entry.w>     # write them; the entry is checked
//                                            # again and a file that no longer
//                                            # checks is restored
//   --exclude <path-prefix>                  # leave those files alone
//   --std                                    # rewrite lib/std too (never a migrated corpus, D112)
//
// A std file reached through the embedded prelude is never rewritten here:
// the entry's own files and the files on disk it imports are.
use std.process
use std.collections.HashMap
use std.builtins.eprint
use compiler.Compilation
use Ast
use Sema
use SemaTypes
use rt.rt_core

type CeremonyEdit {
    path: str,
    start: i32,
    end: i32,
    replacement: str,
    what: str,
}

// An initializer typed without the annotation's demand (§4.3c, D93, D22):
// a read of a place, a string, a cast (its type is written), a call of a
// non-generic function, and operators over those. A literal, a collection
// literal, a comprehension, a variant shorthand, `None`/`Some`, an `if` or
// `match`, a closure and a generic call take their type from the demand, so
// the annotation may be what types them; they are left alone.
fn cf_demand_free(sema: &Sema, pool: &AstPool, node: i32) -> bool:
    if node == 0: return false
    let kind = pool.kind(node)
    // A bare `None` (an ident that names a variant) takes its enum from the demand.
    if kind == NodeKind.NK_IDENT: return not sema.variant_lookup.contains(pool.get_data0(node))
    if kind == NodeKind.NK_FIELD_ACCESS or kind == NodeKind.NK_INDEX or kind == NodeKind.NK_CAST or kind == NodeKind.NK_STRING_LIT or kind == NodeKind.NK_FSTRING: return true
    if kind == NodeKind.NK_UNARY: return cf_demand_free(sema, pool, pool.get_data1(node))
    if kind == NodeKind.NK_BINARY: return cf_demand_free(sema, pool, pool.get_data1(node)) and cf_demand_free(sema, pool, pool.get_data2(node))
    if kind == NodeKind.NK_CALL:
        let callee = sema.comp_resolved.get(node) ?? 0
        if callee == 0: return false
        return sema.generic_fn_node_for_symbol(callee) == 0
    false

// The `(` at `open` groups an expression, as against opening a call's or an
// index's argument list: nothing of a name, a `)` or a `]` precedes it.
fn cf_paren_is_grouping(text: &str, open: i32) -> bool:
    var i = open - 1
    while i >= 0 and (text[i] == ' ' or text[i] == '\t'): i = i - 1
    if i < 0: return true
    let c = text[i]
    not ((c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or (c >= '0' and c <= '9') or c == '_' or c == ')' or c == ']')

// The names a diagnostic quotes in backticks.
fn cf_quoted_names(message: &str) -> List[str]:
    let parts = message.split("`")
    [with_str_clone_ref(parts[i]) for i in 0..parts.len() if i % 2 == 1 and parts[i].len() > 0]

// The byte just before `at` that is a colon, skipping blanks: where a
// `let x: T` annotation begins.
fn cf_colon_before(text: &str, at: i32) -> i32:
    var i = at - 1
    while i >= 0 and (text[i] == ' ' or text[i] == '\t'): i = i - 1
    if i >= 0 and text[i] == ':': i else: -1

fn cf_line_of(text: &str, at: i32) -> i32:
    var line = 1
    for i in 0..at:
        if text[i] == '\n': line = line + 1
    line

fn cf_excluded(path: &str, excludes: &List[str]) -> bool:
    for prefix in excludes:
        if path.starts_with(prefix): return true
    false

// A path the tool may rewrite: a file on disk, not the embedded std.
fn cf_rewritable(path: &str, excludes: &List[str], std_too: bool) -> bool:
    // A migrated corpus is never edited (D112); the standard library only on
    // request (a program's entry reaches it compiled from source under a
    // :dev stage1).
    if path.starts_with("lib/std/engines/") or path.starts_with("test/corpora/") or path.contains("/lib/std/engines/"): return false
    if not std_too and (path.starts_with("lib/std/") or path.contains("/lib/std/")): return false
    path.len() > 0 and not path.starts_with("<") and not cf_excluded(path, excludes) and with_fs_read_file(path).len() > 0

fn cf_collect(sema: &Sema, pool: &AstPool, excludes: &List[str], std_too: bool) -> List[CeremonyEdit]:
    let edits = []
    let texts: HashMap[str, str] = [:]
    for (node, path) in sema.ceremony_let_paths:
        if not cf_rewritable(path, excludes, std_too): continue
        if not texts.contains(path): texts.insert(with_str_clone_ref(path), with_fs_read_file(path))
        let text = texts.get(path).unwrap()
        // The census's typed patterns (SemaDiag.w): `.clone()` on a str
        // (D111: a str is a value), an explicit `&x` at a `&T` parameter
        // (§3.8 auto-references), `Some(x)` where an Option is demanded
        // (D103: the demand converts). Each is its inner expression.
        if sema.ceremony_sites.contains(node):
            let pattern = sema.ceremony_sites.get(node).unwrap()
            if pattern == 1:
                let recv = pool.get_data0(pool.get_data0(node))
                edits.push(CeremonyEdit { path: with_str_clone_ref(path), start: pool.get_end(recv), end: pool.get_end(node), replacement: "", what: "`.clone()` on a str: a str is a value (D111)" })
            else if pattern == 2:
                let inner = pool.get_data1(node)
                edits.push(CeremonyEdit { path: with_str_clone_ref(path), start: pool.get_start(node), end: pool.get_start(inner), replacement: "", what: "`&x` at a `&T` parameter auto-references (§3.8)" })
            else if pattern == 3:
                let arg = pool.get_extra(pool.get_data1(node))
                edits.push(CeremonyEdit { path: with_str_clone_ref(path), start: pool.get_start(node), end: pool.get_start(arg), replacement: "", what: "`Some(x)` where an Option is demanded: the demand converts (D103)" })
                edits.push(CeremonyEdit { path: with_str_clone_ref(path), start: pool.get_end(arg), end: pool.get_end(node), replacement: "", what: "the closing paren" })
            continue
        // `for i in 0..xs.len():` whose every use of `i` is `xs[i]` read: the
        // loop iterates the list, and each `xs[i]` is the element.
        if sema.ceremony_index_loop_bases.contains(node):
            let uses = sema.ceremony_loop_uses.get(node) ?? 0
            let index_uses = sema.ceremony_loop_index_uses.get(node) ?? 0
            if uses > 0 and uses == index_uses and not sema.ceremony_loop_written.contains(node):
                let base = sema.ceremony_index_loop_bases.get(node).unwrap()
                let list_name = sema.pool_resolve(pool.get_data0(base))
                let elem = sema.pool_resolve(sema.ceremony_loop_elem_syms.get(node).unwrap())
                let iterable = pool.get_data1(node)
                // `i in 0..xs.len()`: from the counter's name to the range's end.
                var counter_start = pool.get_start(node) + 3
                while counter_start < text.len() and text[counter_start] == ' ': counter_start = counter_start + 1
                edits.push(CeremonyEdit { path: with_str_clone_ref(path), start: counter_start, end: pool.get_end(iterable), replacement: elem ++ " in " ++ list_name, what: "`for i in 0..xs.len()` indexes only `xs`: it iterates the list" })
                for (index_node, owner) in sema.ceremony_loop_index_nodes:
                    if owner == node: edits.push(CeremonyEdit { path: with_str_clone_ref(path), start: pool.get_start(index_node), end: pool.get_end(index_node), replacement: with_str_clone_ref(elem), what: "the element" })
            continue
        // A widening `as` under a demand of its target: the cast goes, the
        // source stays (`x as i64` where an i64 is demanded → `x`).
        if sema.ceremony_widening_casts.contains(node):
            let src = sema.ceremony_widening_casts.get(node).unwrap()
            let cast_start = pool.get_start(node)
            let cast_end = pool.get_end(node)
            // `(x as u32)` written as a shift count or an operand: the parens held
            // the cast, and go with it.
            let wrapped = cast_start > 0 and cast_end < text.len() and text[cast_start - 1] == '(' and text[cast_end] == ')' and cf_paren_is_grouping(text, cast_start - 1)
            let what = "`as " ++ sema.type_name(sema.typed_expr_types.get(node) ?? 0) ++ "` widens where the context already does (§4.2.6)"
            if wrapped: edits.push(CeremonyEdit { path: with_str_clone_ref(path), start: cast_start - 1, end: cast_start, replacement: "", what: with_str_clone_ref(what) })
            edits.push(CeremonyEdit { path: with_str_clone_ref(path), start: pool.get_end(src), end: if wrapped: cast_end + 1 else: cast_end, replacement: "", what: what })
            continue
        // `List.new()` / `HashMap.new()` / `HashSet.new()` as a let's
        // initializer with its type written: the empty literal (D93).
        if sema.ceremony_list_news.contains(node):
            let value = sema.ceremony_let_values.get(node).unwrap()
            let callee = pool.get_data0(value)
            let owner = pool.get_data0(callee)
            let name = sema.pool_resolve(pool.get_data0(owner))
            let literal = if name == "HashMap": "[:]" else: "[]"
            edits.push(CeremonyEdit { path: with_str_clone_ref(path), start: pool.get_start(value), end: pool.get_end(value), replacement: literal, what: "`" ++ name ++ ".new()` under a written type is `" ++ literal ++ "` (D93)" })
        let flags = pool.get_data2(node)
        // The annotation: the type node's span, and the colon before it. A cast
        // initializer whose cast goes keeps the annotation: it is the demand
        // the cast removal relies on (`var h: i64 = base as i64` → `var h: i64 = base`).
        if sema.ceremony_let_annotations.contains(node):
            let ann = sema.resolve_alias(sema.ceremony_let_annotations.get(node).unwrap() as TypeId) as i32
            let value = sema.ceremony_let_values.get(node).unwrap()
            let value_ty = sema.resolve_alias((sema.typed_expr_types.get(value) ?? 0) as TypeId) as i32
            if value_ty != 0 and value_ty == ann and cf_demand_free(sema, pool, value) and not sema.ceremony_widening_casts.contains(value):
                let type_node = sema.ceremony_let_type_nodes.get(node).unwrap()
                let type_start = pool.get_start(type_node)
                let colon = cf_colon_before(text, type_start)
                if colon >= 0:
                    edits.push(CeremonyEdit { path: with_str_clone_ref(path), start: colon, end: pool.get_end(type_node), replacement: "", what: "annotation `: " ++ sema.type_name(ann) ++ "` restates the initializer's type" })
        // `var` never rebound: the keyword at the statement's start.
        if flags % 2 == 1 and not sema.ceremony_rebound_lets.contains(node):
            let start = pool.get_start(node)
            if start + 3 <= text.len() and text.slice(start, start + 3) == "var":
                edits.push(CeremonyEdit { path: with_str_clone_ref(path), start, end: start + 3, replacement: "let", what: "`var` is never rebound: `let`" })
    edits

// Apply a file's edits from the end back, so earlier offsets stay valid.
fn cf_rewrite(text: &str, edits: &List[CeremonyEdit]) -> str:
    let order = [i for i in 0..edits.len()]
    // Insertion sort by start, descending: a file has few edits.
    for a in 1..order.len():
        var b = a
        while b > 0 and edits[order[b - 1]].start < edits[order[b]].start:
            let t = order[b - 1]
            order[b - 1] = order[b]
            order[b] = t
            b = b - 1
    var out = with_str_clone_ref(text)
    for i in order:
        let e = &edits[i]
        out = out.slice(0, e.start) ++ e.replacement ++ out.slice(e.end, out.len())
    out

fn run_ceremony_fix() -> i32:
    let argv = args()
    var apply = false
    var std_too = false
    var check_with = ""
    var entry = ""
    let excludes = []
    var i = 2
    while i < argv.len():
        if argv[i] == "--apply": apply = true
        else if argv[i] == "--std": std_too = true
        else if argv[i] == "--report": apply = false
        else if argv[i] == "--check-with" and i + 1 < argv.len():
            i = i + 1
            check_with = argv[i]
        else if argv[i] == "--exclude" and i + 1 < argv.len():
            i = i + 1
            excludes.push(argv[i])
        else: entry = argv[i]
        i = i + 1
    if entry.len() == 0:
        print("usage: with fix-ceremony [--report|--apply] [--exclude path ...] [--check-with compiler] <entry.w>")
        return 2
    let comp = Compilation.init()
    let pool = comp.compile_entry_file(entry)
    if pool.decl_count() == 0 or comp.zcu.diagnostics.has_errors():
        eprint(f"fix-ceremony: {entry} does not check; fix it first")
        return 1
    let edits = cf_collect(comp.zcu.last_sema, pool, excludes, std_too)
    let paths = []
    for e in edits:
        if not paths.contains(e.path): paths.push(with_str_clone_ref(e.path))
    for path in paths:
        let text = with_fs_read_file(path)
        for e in edits:
            if e.path == path: print(f"{path}:{cf_line_of(text, e.start)}: {e.what}")
    print(f"fix-ceremony: {edits.len()} rewrite(s) in {paths.len()} file(s)")
    if not apply or edits.len() == 0: return 0
    let originals: HashMap[str, str] = [:]
    for path in paths:
        let text = with_fs_read_file(path)
        originals.insert(with_str_clone_ref(path), with_str_clone_ref(text))
        let mine = [e for e in edits if e.path == path]
        if with_fs_write_file(path, cf_rewrite(text, mine)) != 0:
            eprint(f"fix-ceremony: could not write {path}")
            return 1
    // The proof: the entry still checks with every rewrite in. If not, every
    // rewritten file is restored; the report above says what was tried.
    let again = Compilation.init()
    let pool2 = again.compile_entry_file(entry)
    if pool2.decl_count() == 0 or again.zcu.diagnostics.has_errors():
        for (path, text) in originals: with_fs_write_file(path, text)
        eprint(f"fix-ceremony: {entry} no longer checks with the rewrites applied; every file restored (a fact the rewriter relied on is wrong — file it)")
        return 1
    // --check-with: a second compiler must accept the result too (the pinned
    // seed, for `src/`: stage1 is its build). A rewrite it refuses is kept as
    // written and reported, line by line, until it checks; a refusal at a
    // line no rewrite touched restores everything.
    if check_with.len() > 0:
        let edit_lines = [cf_line_of(originals.get(e.path).unwrap(), e.start) for e in edits]
        let dropped = [false for e in edits]
        let out_path = "out/fix-ceremony-check.out"
        let err_path = "out/fix-ceremony-check.err"
        while true:
            let fin = run_to_files([with_str_clone_ref(check_with), "check", with_str_clone_ref(entry)], out_path, err_path, 0)
            if fin.code == 0: break
            var progress = false
            var last_message = ""
            for line in (with_fs_read_file(err_path)).split("\n"):
                if line.starts_with("error"): last_message = with_str_clone_ref(line)
                if not line.contains("--> "): continue
                let loc = line.split("--> ")[1].split(":")
                if loc.len() < 2: continue
                let epath = loc[0]
                let eline: i32 = loc[1].parse() ?? 0
                // The refusal names a use. When its message quotes a name
                // (`while \`x\` is a live view`, `cannot move out of global \`g\``),
                // the rewrite that caused it is the nearest rewritten line above
                // that mentions the name; otherwise the nearest within a few lines.
                let names = cf_quoted_names(last_message)
                let source_lines = originals.get(epath).unwrap().split("\n")
                var best = -1
                for ei in 0..edits.len():
                    let e = &edits[ei]
                    if dropped[ei] or e.path != epath or edit_lines[ei] > eline + 1: continue
                    let text_at = source_lines[edit_lines[ei] - 1]
                    var mentions = false
                    for name in names:
                        if text_at.contains(name): mentions = true
                    let near = edit_lines[ei] >= eline - 12
                    if (mentions or (names.len() == 0 and near)) and (best < 0 or edit_lines[ei] > edit_lines[best]): best = ei
                if best < 0 and names.len() > 0:
                    for ei in 0..edits.len():
                        if dropped[ei] or edits[ei].path != epath or edit_lines[ei] > eline + 1 or edit_lines[ei] < eline - 12: continue
                        if best < 0 or edit_lines[ei] > edit_lines[best]: best = ei
                if best < 0: continue
                for ei in 0..edits.len():
                    let e = &edits[ei]
                    if not dropped[ei] and e.path == epath and edit_lines[ei] == edit_lines[best]:
                        dropped[ei] = true
                        progress = true
            if not progress:
                for (path, text) in originals: with_fs_write_file(path, text)
                eprint(f"fix-ceremony: {check_with} refuses {entry} at lines no rewrite touched (see {err_path}); every file restored")
                return 1
            for path in paths:
                let mine = [edits[ei] for ei in 0..edits.len() if edits[ei].path == path and not dropped[ei]]
                with_fs_write_file(path, cf_rewrite(originals.get(path).unwrap(), mine))
        var kept_count = 0
        for ei in 0..edits.len():
            let e = &edits[ei]
            if dropped[ei]:
                kept_count = kept_count + 1
                print(f"{e.path}:{edit_lines[ei]}: kept as written, {check_with} refuses it: {e.what}")
        if kept_count > 0: print(f"fix-ceremony: {kept_count} rewrite(s) kept as written for {check_with}")
    print(f"fix-ceremony: applied; {entry} checks")
    0
