// flag_locals_to_bool.w — a local that holds a yes/no holds a `bool`
// (#2857, D177). `let f = if c: 1 else: 0` becomes `let f = c` (`: 0 else:
// 1` becomes `not c`) when every use of `f` in its function is a test, and
// those tests follow: `f != 0` / `f == 1` read `f`, `f == 0` / `f != 1`
// read `not f`, `f = 1` / `f = 0` assign `true` / `false`. A local that is
// read as a number anywhere — an offset added, an index, a value handed
// on or stored — is the integer it is: `let f = c as i32` (§4.2a: `bool
// as int` is 1 or 0), its uses untouched. A nested `if` is not a flag.
//
//   with run tools/flag_locals_to_bool.w [FILE...]   (default: every src/*.w)
use std.fs
use std.process
use std.string

let argv = args()
var files: List[str] = List.new()
if argv.len() > 1:
    for i in 1..argv.len(): files.push(argv[i])
else:
    for p in list_files_text("src").split("\n"):
        if p.ends_with(".w"): files.push(p)
    for p in list_files_text("src/compiler").split("\n"):
        if p.ends_with(".w"): files.push(p)

fn indent_of(line: &str) -> isize:
    var n: isize = 0
    while n < line.len() and line.byte_at(n) == ' ': n += 1
    n

fn is_name_char(c: i32) -> bool:
    (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or (c >= '0' and c <= '9') or c == '_'

// Whether the condition needs parentheses under `not` (a top-level `and`/`or`).
fn needs_parens(cond: &str) -> bool:
    var depth = 0
    var i: isize = 0
    while i < cond.len():
        let c = cond.byte_at(i)
        if c == '(' or c == '[': depth += 1
        else if c == ')' or c == ']': depth -= 1
        else if depth == 0 and (cond.slice(i, cond.len()).starts_with(" and ") or cond.slice(i, cond.len()).starts_with(" or ")): return true
        i += 1
    false

fn rewrite_use(line: &str, name: &str, is_var: bool) -> str:
    var out: str = line
    out = out.replace(name ++ " != 0", name).replace(name ++ " == 1", name)
    out = out.replace(name ++ " == 0", "not " ++ name).replace(name ++ " != 1", "not " ++ name)
    if is_var:
        if out.ends_with(name ++ " = 1"): out = out.slice(0, out.len() - 1) ++ "true"
        if out.ends_with(name ++ " = 0"): out = out.slice(0, out.len() - 1) ++ "false"
    out

// Whether every whole-word occurrence of `name` on the (rewritten) line is
// a test: preceded by `if `, `elif `, `while `, `and `, `or `, `not ` or
// `(`, and followed by `:`, `)`, ` and`, ` or` or the line's end.
fn uses_only_as_test(line: &str, name: &str, is_var: bool) -> bool:
    var at: isize = 0
    while true:
        let f = line.find(name, at)
        if f < 0: return true
        at = f + name.len()
        if f > 0 and is_name_char(line.byte_at(f - 1)): continue
        if at < line.len() and is_name_char(line.byte_at(at)): continue
        let before: str = line.slice(0, f)
        let after: str = line.slice(at, line.len())
        if is_var and (after == " = true" or after == " = false") and before.trim().len() == 0: continue
        let prev_ok = before.ends_with("if ") or before.ends_with("elif ") or before.ends_with("while ") or before.ends_with("and ") or before.ends_with("or ") or before.ends_with("not ") or (before.ends_with("(") and (before.len() < 2 or not is_name_char(before.byte_at(before.len() - 2))))
        let next_ok = after.len() == 0 or after.starts_with(":") or after.starts_with(")") or after.starts_with(" and ") or after.starts_with(" or ")
        if not (prev_ok and next_ok): return false
    true

var decls = 0
var ints = 0
var uses = 0
for path in files:
    let text = read_file(path) ?? ""
    var lines: List[str] = List.new()
    for l in text.split("\n"): lines.push(l)
    var changed = false
    for i in 0..lines.len():
        let line: str = lines[i]
        let caps = /^(\s*)(let|var) ([a-z_][a-z0-9_]*)(: i32)? = if (.+): (1|0) else: (1|0)$/.captures(line)
        if caps.is_none(): continue
        let g = caps.unwrap()
        let then_lit: str = g.get(6).unwrap().text
        let else_lit: str = g.get(7).unwrap().text
        if then_lit == else_lit: continue
        let cond: str = g.get(5).unwrap().text
        if cond.contains(": ") or cond.contains(" else"): continue
        let name: str = g.get(3).unwrap().text
        let keyword: str = g.get(2).unwrap().text
        let is_var = keyword == "var"
        let indent: str = g.get(1).unwrap().text
        // The function's extent: the first later line indented no deeper
        // than the enclosing `fn` line is outside it.
        var fn_indent: isize = 0
        var k = i - 1
        while k >= 0:
            let t: str = lines[k].trim_start()
            if (t.starts_with("fn ") or t.contains(" fn ")) and indent_of(lines[k]) < indent_of(line):
                fn_indent = indent_of(lines[k])
                break
            k -= 1
        var end = i + 1
        while end < lines.len() and (lines[end].trim().len() == 0 or indent_of(lines[end]) > fn_indent): end += 1
        var all_tests = true
        for j in (i + 1)..end:
            if not uses_only_as_test(rewrite_use(lines[j], name, is_var), name, is_var):
                all_tests = false
                break
        if not all_tests:
            let value: str = if then_lit == "1": "(" ++ cond ++ ") as i32" else: "(not (" ++ cond ++ ")) as i32"
            lines[i] = indent ++ keyword ++ " " ++ name ++ " = " ++ value
            ints += 1
            changed = true
            continue
        let value: str = if then_lit == "1": cond else: (if needs_parens(cond): "not (" ++ cond ++ ")" else: "not " ++ cond)
        lines[i] = indent ++ keyword ++ " " ++ name ++ " = " ++ value
        for j in (i + 1)..end:
            let out = rewrite_use(lines[j], name, is_var)
            if out != lines[j]:
                lines[j] = out
                uses += 1
        decls += 1
        changed = true
    if changed:
        var out = ""
        for k in 0..lines.len(): out = out ++ lines[k] ++ (if k + 1 < lines.len(): "\n" else: "")
        if write_file(path, out) != 0:
            eprint(f"flag_locals_to_bool: cannot write {path}")
            exit_code(1)
print(f"rewrote {decls} flag local(s) to bool with {uses} use line(s); {ints} counted local(s) read their flag `as i32`")
