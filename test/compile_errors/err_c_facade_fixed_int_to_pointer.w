//! expect-check-fail: binds an integer to param 1: *const i8 tail, which is not an integer

// D64 §16.2b.11: a pointer parameter is fixed to `null`, not to a number.
use c_import("static inline int add3(int a, const char *tail) { return a; }\n")

c facade adds:
    fn add3
        param tail fixed 0

fn main:
    print("unreachable")
