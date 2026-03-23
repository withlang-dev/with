//! expect-check-fail: argument(s), found

// Test: calling a function with the wrong number of arguments is rejected.

fn add(a: i32, b: i32) -> i32:
    a + b

fn main:
    add(1)
