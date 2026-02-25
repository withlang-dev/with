// Test: Result chaining with try operator
fn divide(a: i32, b: i32) -> Result[i32, i32] =
    if b == 0 then Err(1) else Ok(a / b)

fn safe_divide(a: i32, b: i32) -> i32 =
    divide(a, b) ?? -1

fn main() -> i32 =
    // Success case
    let a = safe_divide(10, 2)
    assert(a == 5)

    // Error case with default
    let b = safe_divide(10, 0)
    assert(b == -1)

    0
