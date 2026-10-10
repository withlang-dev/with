//! expect-stdout: fields awk 3:<beta><20><y>
//! expect-stdout: fields blanks 3:<a><b><c>
//! expect-stdout: fields empty 0:
//! expect-stdout: fields all-blank 0:
//! expect-stdout: fields one 1:<solo>
//! expect-stdout: fields crlf 2:<x><y>
//! expect-stdout: split vs fields 4 2

// #959: awk-style field splitting for one-liners. `str.fields()` splits on
// runs of whitespace and makes no empty field for leading, trailing or
// repeated blanks; `split(" ")` does.

fn show_fields(label: &str, s: &str):
    let f = s.fields()
    var shown = ""
    for x in f:
        shown = shown ++ "<" ++ x ++ ">"
    print(f"fields {label} {f.len()}:{shown}")

fn main:
    show_fields("awk", "beta  20 y")
    show_fields("blanks", " \t a  b\tc \n")
    show_fields("empty", "")
    show_fields("all-blank", "  \t ")
    show_fields("one", "solo")
    show_fields("crlf", "x y\r\n")
    let s = " a  b"
    let parts = s.split(" ")
    print(f"split vs fields {parts.len()} {s.fields().len()}")
