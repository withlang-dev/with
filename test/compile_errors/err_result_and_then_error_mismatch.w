//! expect-error: Result.and_then

fn step(value: i32) -> Result[i32, i32]:
    Ok(value + 1)

fn main:
    let x: Result[i32, str] = Ok(1)
    let _ = x.and_then(value => step(value))
