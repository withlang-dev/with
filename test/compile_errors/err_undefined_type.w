//! expect-check-fail: unknown type

// Test: using a type name that doesn't exist is rejected.

fn main:
    let x: NoSuchType = 42
