//! expect-check-fail: closure return type mismatch

// §9.1 / §4.10 / D60: under an expected `fn() -> i32` the closure's tail
// assignment is its value, a bool — a type error, not `i32.default()`.

var flag: bool = false
fn main:
    let f: fn() -> i32 = () => flag = true
    print(f())
