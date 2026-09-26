//! expect-check-fail: type mismatch in binding

// #1711: a float has no arithmetic type against bool, Unit or str. The
// float branch of arithmetic_result_type answered the float for any
// partner, so `let x: f64 = true` type-checked and failed as invalid MIR.

fn main:
    let x: f64 = true
    print(f"{x}")
