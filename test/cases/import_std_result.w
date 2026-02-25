// Test: Result methods directly (no import needed)
fn main() -> i32 =
    let ok_val: Result[i32, i32] = Ok(42)
    let err_val: Result[i32, i32] = Err(99)

    assert(ok_val.is_ok())
    assert(err_val.is_err())
    assert(ok_val.unwrap_or(0) == 42)
    assert(err_val.unwrap_or(0) == 0)

    0
