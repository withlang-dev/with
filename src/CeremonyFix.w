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
    if kind == NodeKind.NK_IDENT or kind == NodeKind.NK_FIELD_ACCESS or kind == NodeKind.NK_INDEX or kind == NodeKind.NK_CAST or kind == NodeKind.NK_STRING_LIT or kind == NodeKind.NK_FSTRING: return true
    if kind == NodeKind.NK_UNARY: return cf_demand_free(sema, pool, pool.get_data1(node))
    if kind == NodeKind.NK_BINARY: return cf_demand_free(sema, pool, pool.get_data1(node)) and cf_demand_free(sema, pool, pool.get_data2(node))
    if kind == NodeKind.NK_CALL:
        let callee = sema.comp_resolved.get(node) ?? 0
        if callee == 0: return false
        return sema.generic_fn_node_for_symbol(callee) == 0
    false

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
    let texts: HashMap[str, str] = HashMap.new()
    for (node, path) in sema.ceremony_let_paths:
        if not cf_rewritable(path, excludes, std_too): continue
        if not texts.contains(path): texts.insert(with_str_clone_ref(path), with_fs_read_file(path))
        let text = texts.get(path).unwrap()
        let flags = pool.get_data2(node)
        // The annotation: the type node's span, and the colon before it.
        if sema.ceremony_let_annotations.contains(node):
            let ann = sema.resolve_alias(sema.ceremony_let_annotations.get(node).unwrap() as TypeId) as i32
            let value = sema.ceremony_let_values.get(node).unwrap()
            let value_ty = sema.resolve_alias((sema.typed_expr_types.get(value) ?? 0) as TypeId) as i32
            if value_ty != 0 and value_ty == ann and cf_demand_free(sema, pool, value):
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
    var entry = ""
    let excludes = []
    var i = 2
    while i < argv.len():
        if argv[i] == "--apply": apply = true
        else if argv[i] == "--std": std_too = true
        else if argv[i] == "--report": apply = false
        else if argv[i] == "--exclude" and i + 1 < argv.len():
            i = i + 1
            excludes.push(argv[i])
        else: entry = argv[i]
        i = i + 1
    if entry.len() == 0:
        print("usage: with fix-ceremony [--report|--apply] [--exclude path ...] <entry.w>")
        return 2
    var comp = Compilation.init()
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
    let originals: HashMap[str, str] = HashMap.new()
    for path in paths:
        let text = with_fs_read_file(path)
        originals.insert(with_str_clone_ref(path), with_str_clone_ref(text))
        let mine = [e for e in edits if e.path == path]
        if with_fs_write_file(path, cf_rewrite(text, mine)) != 0:
            eprint(f"fix-ceremony: could not write {path}")
            return 1
    // The proof: the entry still checks with every rewrite in. If not, every
    // rewritten file is restored; the report above says what was tried.
    var again = Compilation.init()
    let pool2 = again.compile_entry_file(entry)
    if pool2.decl_count() == 0 or again.zcu.diagnostics.has_errors():
        for (path, text) in originals: with_fs_write_file(path, text)
        eprint(f"fix-ceremony: {entry} no longer checks with the rewrites applied; every file restored (a fact the rewriter relied on is wrong — file it)")
        return 1
    print(f"fix-ceremony: applied; {entry} checks")
    0
