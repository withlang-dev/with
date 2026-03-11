//! expect-check-fail: arithmetic operator requires numeric operands

// Test: binary operator type error when mixing int and string.

fn main:
    let x = 5 + "hello"
