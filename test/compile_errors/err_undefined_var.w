//! expect-check-fail: undefined variable

// Test: referencing an undefined variable is rejected.

fn main:
    print(int_to_string(x))
