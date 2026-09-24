//! expect-check-fail: fixed null' binds param 1: i32 b, which is not a pointer

// D64 §16.2b.11: the literal is a value of the C parameter's type.
use c_import("static inline int add3(int a, int b, const char *tail) { return a + b; }\n")

c facade adds:
    fn add3
        param b fixed null
        param tail fixed null

fn main:
    print("unreachable")
