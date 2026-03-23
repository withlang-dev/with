//! expect-check-fail: format mode requires integer type
fn main:
    let x = 3.14
    println(f"{x:x}")
