// Test option chaining and combinators
fn safe_div(a: i32, b: i32) -> ?i32 =
    if b == 0: None
    else Some(a / b)

fn main() -> i32 =
    let r1 = safe_div(10, 2)
    let r2 = safe_div(10, 0)
    println(r1 ?? -1)
    println(r2 ?? -1)
    // Chain with map
    let r3 = safe_div(20, 4)
    match r3
        Some(v) -> println(v)
        None -> println(-1)
    0
