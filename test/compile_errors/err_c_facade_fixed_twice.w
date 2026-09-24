//! expect-check-fail: is fixed twice

// D64 §16.2b.11: one parameter, one literal.
use c_import("static inline int add3(int a, int b) { return a + b; }\n")

c facade adds:
    fn add3
        param b fixed 5
        param b fixed 6

fn main:
    print("unreachable")
