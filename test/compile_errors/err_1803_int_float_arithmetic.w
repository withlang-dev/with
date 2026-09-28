//! expect-error: arithmetic on `i32` and `f64` needs an explicit `as` on one operand

// §4.2.6: no implicit integer-to-float conversion, in an operator either; a
// float literal cannot take an integer peer's type. `i * 2.5` was f64.
fn main:
    let i: i32 = 3
    print(f"{i * 2.5}")
