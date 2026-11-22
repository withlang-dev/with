//! expect-check-fail: not a pointer, NULL is not a value it can take
//! expect-check-fail: = help: delete 'nullable param 0'

// #3129 (§16.2b.8): `nullable` on a parameter that is not a pointer.
use c_import("static inline int add3(int a, int b) { return a + b; }\n")

c contract adds:
    fn add3
        nullable param a

fn main:
    print("unreachable")
