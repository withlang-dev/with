// Test: Result.and_then chaining
fn plus_one(x: i32) -> Result[i32, i32]:
    Ok(x + 1)

fn fail_if_odd(x: i32) -> Result[i32, i32]:
    if x % 2 == 1 then Err(99) else Ok(x)

fn main -> i32:
    let a: Result[i32, i32] = Ok(10)
    let b = a.and_then(plus_one)
    assert(b.is_ok())
    assert(b.unwrap() == 11)

    let c = b.and_then(fail_if_odd)
    assert(c.is_err())
