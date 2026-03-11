//! expect-check-fail: undefined variable

// Test: referencing an undefined variable is rejected.

fn main:
    println(int_to_string(x))
