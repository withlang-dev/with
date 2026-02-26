fn divide(a: i32, b: i32) -> Result[i32, str] =
    if b == 0: Err("division by zero")
    else Ok(a / b)

fn main() -> i32 =
    let a = divide(10, 2) ?? -1
    let b = divide(10, 0) ?? -1
    println(a)
    println(b)
    0
