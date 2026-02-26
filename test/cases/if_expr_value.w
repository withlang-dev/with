fn abs(x: i32) -> i32 =
    if x >= 0: x else 0 - x

fn sign(x: i32) -> i32 =
    if x > 0: 1
    else if x < 0: -1
    else 0

fn main() -> i32 =
    println(abs(5))
    println(abs(-3))
    println(sign(10))
    println(sign(-7))
    println(sign(0))
    0
