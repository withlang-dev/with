//! expect-stdout: 5
//! expect-stdout: 3
//! expect-stdout: 2
//! expect-stdout: 5
//! expect-stdout: 0

// #1810: a `&str` view lent to a c_imported `const char *` (D47, #1589):
// a view parameter, a range view (whose bytes are not NUL-terminated at the
// range's end), an element view, and a field view each reach C as a
// NUL-terminated copy of exactly the view's bytes.

use c_import("unsigned long strlen(const char *s);\n")

type Rec { name: str }

fn clen(s: &str) -> usize: strlen(s)

fn main:
    let h = "hello"
    let r: &str = h
    print(clen(r))
    print(strlen(r[1..4]))
    var xs: List[str] = List.new()
    xs.push("ab")
    print(strlen(xs[0]))
    let rec = Rec { name: "fives" }
    print(strlen(rec.name))
    print(strlen(r[2..2]))
