//! expect-check-fail: does not match

// Test: enum variant shorthand with non-existent variant is rejected.

type Color = Red | Green | Blue

fn main:
    let c: Color = .Yellow
