// Test implicit Ok wrapping for Result-returning functions

fn safe_div(a: i32, b: i32) -> Result[i32, i32] =
    if b == 0:
        Err(0)
    else
        a / b

fn always_ok() -> Result[i32, i32] =
    42

fn main() -> i32 =
    let r1 = safe_div(10, 2)
    let v1 = r1 ?? 0
    assert(v1 == 5)

    let r2 = safe_div(10, 0)
    let v2 = r2 ?? -1
    assert(v2 == -1)

    let r3 = always_ok()
    let v3 = r3 ?? 0
    assert(v3 == 42)
    0
