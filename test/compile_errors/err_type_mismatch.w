//! expect-check-fail: type mismatch in binding

// Test: assigning a string to a variable declared as i32 is rejected.

fn main:
    let x: i32 = "hello"
