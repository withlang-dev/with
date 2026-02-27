// Test Option and Result conversions
fn divide(a: i32, b: i32) -> Result[i32, str]:
    if b == 0: Err("division by zero")
    else Ok(a / b)

fn safe_get(idx: i32) -> ?i32:
    if idx >= 0 and idx < 5:
        Some(idx * 10)
    else
        None

fn main -> i32:
    match divide(10, 2)
        Ok(v) -> println(v)
        Err(e) -> println(e)
    match divide(10, 0)
        Ok(v) -> println(v)
        Err(e) -> println(e)
    println(safe_get(2) ?? -1)
    println(safe_get(10) ?? -1)
