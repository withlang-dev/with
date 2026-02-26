fn max(a: i32, b: i32) -> i32 =
    if a > b: a else b

fn min(a: i32, b: i32) -> i32 =
    if a < b: a else b

fn main() -> i32 =
    println(max(10, 20))
    println(min(10, 20))
    println(max(-5, -3))
    println(min(-5, -3))
    0
