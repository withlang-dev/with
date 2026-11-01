// predicate_to_bool.w — a function that answers yes/no returns `bool`
// (#2857). Compiler-driven: the sites are Sema's own census record
// (`with check ROOT --ceremony-census`, pattern `i32-predicate`: a function
// declared to return an integer whose every result is the literal 0 or 1,
// both occurring), restricted to the names listed in NAMES (one per line,
// the bare name or `Type.name`). Within each declaration's byte span the
// return type becomes `bool` and the literal results `false`/`true`; across
// the tree a call followed by `!= 0` drops the comparison and one followed
// by `== 0` compares with `false`. D177 keeps both rewrites meaning-
// preserving where the same bare name on another type stays an integer
// (an integer tests true when nonzero). The compiler judges the rest: a
// result used as a number is a function that stays `i32`.
//
//   with run tools/predicate_to_bool.w COMPILER ROOT.w NAMES
use std.fs
use std.process
use std.string

let argv = args()
if argv.len() < 4:
    eprint("usage: predicate_to_bool.w COMPILER ROOT.w NAMES")
    exit_code(2)
let compiler = argv[1]
let root = argv[2]
var names: List[str] = List.new()
for line in (read_file(argv[3]) ?? "").split("\n"):
    let n: str = line.trim()
    if n.len() > 0: names.push(n)

fn in_corpus(path: &str) -> bool:
    var dir: str = path
    while dir.contains("/"):
        dir = dir.slice(0, dir.rfind("/"))
        if file_exists(dir ++ "/corpus.stamp"): return true
    false

fn tree_path(path: &str) -> str:
    if path.starts_with("<embedded-std>/std/"): return "lib/std/" ++ path.slice("<embedded-std>/std/".len(), path.len())
    path

// Where the function declared at `start` ends: the census span ends at the
// signature's last token, so the body is found by indentation — the first
// later non-blank line indented no deeper than the declaration's own line
// (a nested `fn` or a closure body is deeper and stays inside).
fn body_end(text: &str, start: isize, span_end: isize) -> isize:
    var line_start = start
    while line_start > 0 and text.byte_at(line_start - 1) != '\n': line_start -= 1
    var indent = 0
    while text.byte_at(line_start + indent) == ' ': indent += 1
    var at = span_end
    // Past the signature's line.
    while at < text.len() and text.byte_at(at) != '\n': at += 1
    var end = at
    while at < text.len():
        at += 1
        var col = 0
        while at + col < text.len() and text.byte_at(at + col) == ' ': col += 1
        let eol_at = at + col
        if eol_at >= text.len(): break
        let c = text.byte_at(eol_at)
        if c == '\n':
            // A blank line: keep going, it may be inside the body.
            at = eol_at
            continue
        if col <= indent: break
        at = eol_at
        while at < text.len() and text.byte_at(at) != '\n': at += 1
        end = at
    end

// The declared name of the function at `text[start..]`: after `fn `, up to
// `(`, `:`, ` ` or `-`.
fn decl_name(text: &str, start: isize) -> str:
    let head: str = text.slice(start, if start + 200 < text.len(): start + 200 else: text.len())
    if not head.contains("fn "): return ""
    let after: str = head.split("fn ")[1]
    var name = ""
    for i in 0..after.len():
        let ch = after.byte_at(i)
        if ch == '(' or ch == ':' or ch == ' ' or ch == '-': break
        name = name ++ after.slice(i, i + 1)
    name

fn bare(name: &str) -> str:
    if name.contains("."): return name.split(".")[name.split(".").len() - 1]
    with_str_clone_ref(name)

let done = run_to_files(&[compiler, "check", root, "--ceremony-census"], "out/pred-census.txt", "out/pred-census.err", 900000)
if done.code != 0:
    eprint(f"predicate_to_bool: `{compiler} check {root} --ceremony-census` failed (exit {done.code}); see out/pred-census.err")
    exit_code(1)

var site_paths: List[str] = List.new()
var site_starts: List[isize] = List.new()
var site_ends: List[isize] = List.new()
var rewritten: List[str] = List.new()
for line in (read_file("out/pred-census.txt") ?? "").split("\n"):
    let cols = line.split("\t")
    if cols.len() < 5 or cols[0] != "i32-predicate": continue
    let path = tree_path(cols[1])
    if in_corpus(path): continue
    let start: isize = cols[3].parse() ?? -1
    let end: isize = cols[4].parse() ?? -1
    if start < 0 or end <= start: continue
    let text = read_file(path) ?? ""
    let name = decl_name(text, start)
    if not names.contains(name) and not names.contains(bare(name)): continue
    site_paths.push(path)
    site_starts.push(start)
    site_ends.push(end)
    if not rewritten.contains(bare(name)): rewritten.push(bare(name))

// Every listed name has its callers rewritten, found as a site or not: a
// wrapper that returns another predicate's result is made `bool` by hand
// and its callers follow (D177 keeps the rewrite meaning-preserving).
for name in names:
    let b = bare(name)
    if not rewritten.contains(b): rewritten.push(b)

// 1. The declarations, last site first so earlier offsets stay valid.
var files: List[str] = List.new()
for p in site_paths:
    if not files.contains(p): files.push(p)
var decls = 0
for path in files:
    var order: List[isize] = List.new()
    for i in 0..site_paths.len():
        if site_paths[i] == path: order.push(i)
    for a in 0..order.len():
        for b in (a + 1)..order.len():
            if site_starts[order[b]] > site_starts[order[a]]:
                let t: isize = order[a]
                order[a] = order[b]
                order[b] = t
    var out = read_file(path) ?? ""
    for oi in 0..order.len():
        let i = order[oi]
        let s = site_starts[i]
        let e = body_end(out, s, site_ends[i])
        var decl: str = out.slice(s, e)
        if not decl.contains("-> i32"): continue
        decl = decl.replace("-> i32", "-> bool")
        decl = /\breturn 0\b/.replace_all(decl, "return false")
        decl = /\breturn 1\b/.replace_all(decl, "return true")
        decl = decl.replace(": 1 else: 0", ": true else: false").replace(": 0 else: 1", ": false else: true")
        decl = /(\n[ \t]*)1[ \t]*(?=\n|$)/.replace_all(decl, "$1true")
        decl = /(\n[ \t]*)0[ \t]*(?=\n|$)/.replace_all(decl, "$1false")
        // A line-final `: 1` / `: 0` is a result only on a line that binds
        // nothing (`let x = if c: a else: 0` ends the same way and is not).
        var rebuilt = ""
        var first_line = true
        for l in decl.split("\n"):
            var line: str = l
            if not (line.contains("let ") or line.contains("var ") or line.contains(" = ")):
                line = /(:[ \t]*)1[ \t]*$/.replace(line, "$1true")
                line = /(:[ \t]*)0[ \t]*$/.replace(line, "$1false")
            rebuilt = rebuilt ++ (if first_line: "" else: "\n") ++ line
            first_line = false
        decl = rebuilt
        out = out.slice(0, s) ++ decl ++ out.slice(e, out.len())
        decls += 1
    if write_file(path, out) != 0:
        eprint(f"predicate_to_bool: cannot write {path}")
        exit_code(1)

// 2. The callers, over every tracked .w file that is not a corpus.
var ls_argv: List[str] = ["git", "ls-files", "*.w"]
let ls = run_to_files(&ls_argv, "out/pred-ls.txt", "out/pred-ls.err", 120000)
var calls = 0
for path in (read_file("out/pred-ls.txt") ?? "").split("\n"):
    let p: str = path
    if p.len() == 0 or in_corpus(p) or p.starts_with("test/") or p.starts_with("examples/"): continue
    let text = read_file(p) ?? ""
    var out = text
    var changed = false
    for name in rewritten:
        let n: str = name
        var at: isize = 0
        while true:
            let found = out.find(n ++ "(", at)
            if found < 0: break
            // A whole name: not the tail of a longer identifier.
            if found > 0:
                let before = out.byte_at(found - 1)
                if (before >= 'a' and before <= 'z') or (before >= 'A' and before <= 'Z') or (before >= '0' and before <= '9') or before == '_':
                    at = found + 1
                    continue
            // The matching `)`.
            var depth = 0
            var j = found + n.len()
            var close: isize = -1
            while j < out.len():
                let c = out.byte_at(j)
                if c == '(': depth += 1
                else if c == ')':
                    depth -= 1
                    if depth == 0:
                        close = j
                        break
                else if c == '\n' and depth == 0: break
                j += 1
            if close < 0:
                at = found + 1
                continue
            let rest: str = out.slice(close + 1, if close + 8 < out.len(): close + 8 else: out.len())
            if rest.starts_with(" != 0"):
                let after_cmp = out.byte_at(close + 6)
                if not (after_cmp >= '0' and after_cmp <= '9'):
                    out = out.slice(0, close + 1) ++ out.slice(close + 6, out.len())
                    changed = true
                    calls += 1
            else if rest.starts_with(" == 0"):
                let after_cmp = out.byte_at(close + 6)
                if not (after_cmp >= '0' and after_cmp <= '9'):
                    out = out.slice(0, close + 1) ++ " == false" ++ out.slice(close + 6, out.len())
                    changed = true
                    calls += 1
            at = close + 1
    if changed and write_file(p, out) != 0:
        eprint(f"predicate_to_bool: cannot write {p}")
        exit_code(1)
print(f"rewrote {decls} declaration(s) to -> bool and {calls} call site(s); names: {rewritten.len()}")
