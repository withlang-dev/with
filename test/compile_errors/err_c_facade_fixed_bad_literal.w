//! expect-check-fail: a fixed argument is an integer literal

// D64 §16.2b.11: a fixed argument is a literal, never an expression or a
// name the facade would have to evaluate.
use c_import("static inline int add3(int a, int b) { return a + b; }\n")

c facade adds:
    fn add3
        param b fixed a

fn main:
    print("unreachable")
