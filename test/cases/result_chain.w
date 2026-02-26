// Test result chaining and error propagation
fn parse_positive(n: i32) -> Result[i32, str] =
    if n > 0: Ok(n)
    else Err("not positive")

fn double_positive(n: i32) -> Result[i32, str] =
    let v = parse_positive(n)?
    Ok(v * 2)

fn main() -> i32 =
    match double_positive(5)
        Ok(v) -> println(v)
        Err(e) -> println(e)
    match double_positive(-3)
        Ok(v) -> println(v)
        Err(e) -> println(e)
    0
