//! expect-stdout: 13
//! expect-stdout: 13
//! expect-stdout: 13
//! expect-stdout: 3

// #1589 (§16.3c, D47): a `str` or `&str` lent to a translated inline C
// function's `const char *` parameter is marshalled as a NUL-terminated C
// string, exactly as for an extern callee. Codegen keyed the lend on the C
// calling convention, which a translated inline function does not have, so
// strlen read the address of the str header instead: it counted that
// pointer's non-zero low bytes, usually five, sometimes three. The strings
// are thirteen bytes, a length no pointer's byte count reaches, so a header
// address can never pass; the last line counts the calls to show every
// call went through.
use c_import("unsigned long strlen(const char *s);\ntypedef struct box { int n; } box;\nstatic inline unsigned long my_len(box *b, const char *s) { b->n = b->n + 1; return strlen(s); }\n")
fn main:
    var bx = box { n: 0 }
    let b = &raw mut bx
    let s = "hello, world!"
    print(f"{unsafe { my_len(b, s) }}")
    let v: &str = s
    print(f"{unsafe { my_len(b, v) }}")
    let owned = "hello, " ++ "world!"
    print(f"{unsafe { my_len(b, owned) }}")
    print(f"{bx.n}")
