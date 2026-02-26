// Test ? operator chaining with Result
fn parse(s: str) -> Result[i32, str] =
    match s
        "one" -> Ok(1)
        "two" -> Ok(2)
        _ -> Err("parse error")

fn add_parsed(a: str, b: str) -> Result[i32, str] =
    let x = parse(a)?
    let y = parse(b)?
    Ok(x + y)

fn main() -> i32 =
    match add_parsed("one", "two")
        Ok(v) -> println(v)
        Err(e) -> println(e)
    match add_parsed("one", "bad")
        Ok(v) -> println(v)
        Err(e) -> println(e)
    0
