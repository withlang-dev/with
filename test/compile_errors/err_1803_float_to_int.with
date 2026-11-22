//! expect-error: a float where an integer is demanded needs an explicit conversion

// §4.2.6 (#1803): no implicit numeric conversion but a lossless widening.
// `let x: i32 = f` with `f: f64` type-checked, and the binding held the f64.
fn main:
    let f: f64 = 3.7
    let x: i32 = f
    print(f"{x}")
