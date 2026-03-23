//! expect-check-fail: precision requires float or string type
fn main:
    let x = 42
    println(f"{x:.3}")
