// D120 fixture sweep: a compile-error fixture that pinned a move on a
// List of values (List[i32], List[isize], List[i64], List[str]) keeps its
// pinned error on a List of a Drop type, Tok. Mechanical: the element
// type, list literals of numbers or strings, `.push(<literal>)`, and the
// expectation line; the Tok type is declared after the header comments.
use std.fs
use std.process

fn is_digit_byte(b: u8) -> bool: b >= '0' and b <= '9'

// `[1, 2, 3]` or `["a", "b"]` → `[Tok { id: 1 }, Tok { id: 2 }, …]`;
// any other bracket text is left as it is.
fn rewrite_list_literal(inner: &str) -> str:
    if inner.trim().len() == 0: return "[]"
    var out = "["
    var k = 0
    for part in inner.split(","):
        let p = part.trim()
        var ok = p.len() > 0
        for i in 0..p.len():
            if not is_digit_byte(p[i]): ok = false
        let is_str = p.len() >= 2 and p[0] == '"' and p[p.len() - 1] == '"'
        if not ok and not is_str: return "[" ++ inner ++ "]"
        if k > 0: out = out ++ ", "
        k = k + 1
        out = out ++ (if ok: "Tok { id: " ++ p ++ " }" else: f"Tok {{ id: {k} }}")
    out ++ "]"

fn rewrite_line(line: &str) -> str:
    var s = line.replace("List[i32]", "List[Tok]").replace("List[isize]", "List[Tok]").replace("List[i64]", "List[Tok]").replace("List[str]", "List[Tok]")
    // list literals
    var out = ""
    var i = 0
    while i < s.len():
        if s[i] == '[' and (i == 0 or not (s[i - 1] >= 'a' and s[i - 1] <= 'z') and not (s[i - 1] >= 'A' and s[i - 1] <= 'Z') and not (s[i - 1] >= '0' and s[i - 1] <= '9') and s[i - 1] != '_' and s[i - 1] != ']' and s[i - 1] != ')'):
            let close = s.slice(i, s.len()).find("]")
            if close > 0:
                let inner = s.slice(i + 1, i + close)
                out = out ++ rewrite_list_literal(inner)
                i = i + close + 1
                continue
        out = out ++ s.slice(i, i + 1)
        i = i + 1
    s = out
    // `.push(<number>)` / `.push("x")`
    var r = ""
    var j = 0
    while j < s.len():
        if s.slice(j, s.len()).starts_with(".push("):
            let rest = s.slice(j + 6, s.len())
            let close = rest.find(")")
            if close > 0:
                let arg: str = rest.slice(0, close).trim()
                var num = arg.len() > 0
                for q in 0..arg.len():
                    if not is_digit_byte(arg[q]): num = false
                let is_str = arg.len() >= 2 and arg[0] == '"' and arg[arg.len() - 1] == '"'
                if num or is_str:
                    r = r ++ ".push(" ++ (if num: "Tok { id: " ++ arg ++ " }" else: "Tok { id: 1 }") ++ ")"
                    j = j + 6 + close + 1
                    continue
        r = r ++ s.slice(j, j + 1)
        j = j + 1
    r

fn main:
    let argv = args()
    for ai in 1..argv.len():
        let path = argv[ai]
        let text: str = match read_file(path):
            Ok(t) => t
            Err(_) => continue
        if text.len() == 0: continue
        var out = ""
        var declared = false
        for line in text.split("\n"):
            let rewritten = rewrite_line(line)
            if not declared and not line.starts_with("//") and line.trim().len() > 0:
                out = out ++ "type Tok { id: i32 }\nimpl Drop for Tok:\n    move fn drop(): {}\n"
                declared = true
            out = out ++ rewritten ++ "\n"
        if out.ends_with("\n\n"): out = out.slice(0, out.len() - 1)
        write_file(path, out)
        print("rewrote " ++ path)
