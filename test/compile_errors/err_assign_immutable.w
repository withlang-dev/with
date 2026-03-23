//! expect-check-fail: immutable

// Test: assignment to an immutable variable is rejected.

fn main:
    let x = 5
    x = 10
