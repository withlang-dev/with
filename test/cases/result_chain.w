// Test Result chaining
fn parse_int(s: str) -> Result[i32, str] =
    if s == "42" then Ok(42)
    else if s == "0" then Ok(0)
    else Err("parse error")

fn double_result(x: i32) -> Result[i32, str] =
    Ok(x * 2)

fn main() -> i32 =
    match parse_int("42")
        Ok(v) -> println(v)
        Err(e) -> println(e)

    match parse_int("bad")
        Ok(v) -> println(v)
        Err(e) -> println(e)

    // Test ?? default
    let a = parse_int("42") ?? -1
    println(a)

    let b = parse_int("bad") ?? -1
    println(b)
    0
