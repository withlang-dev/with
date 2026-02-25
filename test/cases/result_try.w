fn might_fail(x: i32) -> Result[i32, i32] =
    if x > 0 then Ok(x)
    else Err(-1)

fn caller() -> Result[i32, i32] =
    let val = might_fail(42)?
    Ok(val)

fn main() -> i32 =
    let result = caller()
    result ?? 0
