//! expect-check-fail: 'it' is a reserved keyword and cannot be used as a parameter name [E0953]

fn f(it: i32) -> i32: it

fn main:
    let _ = f(1)
