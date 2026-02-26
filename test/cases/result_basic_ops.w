fn divide(a: i32, b: i32) -> Result[i32, str]:
    if b == 0: Err("zero")
    else Ok(a / b)

fn main -> i32:
    match divide(10, 2)
        Ok(v) -> println(v)
        Err(e) -> println(e)
    match divide(10, 0)
        Ok(v) -> println(v)
        Err(e) -> println(e)
    0
