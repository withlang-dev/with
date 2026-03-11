//! expect-check-fail: return type mismatch

// Test: returning a string from a function declared to return i32 is rejected.

fn get() -> i32:
    return "hello"

fn main:
    let x = get()
