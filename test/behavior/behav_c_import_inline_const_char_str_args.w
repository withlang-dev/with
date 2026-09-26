//! expect-stdout: 5
//! expect-stdout: 5
//! expect-stdout: 5

// #1589 (§16.3c, D47): a `str` or `&str` lent to a translated inline C
// function's `const char *` parameter is marshalled as a NUL-terminated C
// string, exactly as for an extern callee. The `str` argument once failed in
// codegen and the `&str` argument passed the address of the str header.
use c_import("unsigned long strlen(const char *s);\ntypedef struct box { int n; } box;\nstatic inline unsigned long my_len(box *b, const char *s) { b->n = b->n + 1; return strlen(s); }\n")
fn main:
    var bx = box { n: 0 }
    let b = &raw mut bx
    let s = "hello"
    print(f"{unsafe { my_len(b, s) }}")
    let v: &str = s
    print(f"{unsafe { my_len(b, v) }}")
    let owned = "hel" ++ "lo"
    print(f"{unsafe { my_len(b, owned) }}")
