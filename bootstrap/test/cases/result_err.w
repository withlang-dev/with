fn might_fail(x: i32) -> Result[i32, i32]:
    if x > 0 then Ok(x)
    else Err(42)

fn caller -> Result[i32, i32]:
    let val = might_fail(-1)?
    Ok(val + 100)

fn main -> i32:
    let result = caller()
    assert(result ?? 42 == 42)
