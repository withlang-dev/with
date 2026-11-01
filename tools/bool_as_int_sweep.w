// bool_as_int_sweep.w — the last `if c: 1 else: 0` sites (#2857): a bool
// handed to an integer is the cast §4.2a spells, `c as i32` (1 or 0), not
// a bool spelled twice. `if c: 0 else: 1` is `(not c) as i32`. A site whose
// consumer is another width is then a type error the compiler names, and
// takes that width's cast by hand. Comments and nested `if`s are left.
use std.fs
use std.process
let argv = args()
var files: List[str] = List.new()
for p in list_files_text("src").split("\n"):
    if p.ends_with(".w"): files.push(p)
for p in list_files_text("src/compiler").split("\n"):
    if p.ends_with(".w"): files.push(p)
var sites = 0
for path in files:
    let text = read_file(path) ?? ""
    var out = ""
    var changed = false
    for line in text.split("\n"):
        var l: str = line
        if not l.trim_start().starts_with("//"):
            // The innermost `if COND: 1 else: 0` with no `:` or `if` inside COND.
            let a = /\bif ([^:\n]*?): 1 else: 0\b/.captures(l)
            if a.is_some():
                let ca = a.unwrap()
                let cond: str = ca.get(1).unwrap().text
                if not cond.contains("if ") and not l.contains("else if " ++ cond):
                    l = l.replace("if " ++ cond ++ ": 1 else: 0", "(" ++ cond ++ ") as i32")
            let b = /\bif ([^:\n]*?): 0 else: 1\b/.captures(l)
            if b.is_some():
                let cb = b.unwrap()
                let cond: str = cb.get(1).unwrap().text
                if not cond.contains("if ") and not l.contains("else if " ++ cond):
                    l = l.replace("if " ++ cond ++ ": 0 else: 1", "(not (" ++ cond ++ ")) as i32")
        if l != line:
            sites += 1
            changed = true
        out = out ++ l ++ "\n"
    if changed and write_file(path, out.slice(0, out.len() - 1)) != 0: exit_code(1)
print(f"rewrote {sites} site(s)")
