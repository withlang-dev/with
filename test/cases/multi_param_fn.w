fn add3(a: i32, b: i32, c: i32) -> i32 = a + b + c
fn mul2_add(a: i32, b: i32, c: i32) -> i32 = a * b + c
fn max3(a: i32, b: i32, c: i32) -> i32 =
    if a >= b and a >= c: a
    else if b >= c: b
    else c

fn main() -> i32 =
    println(add3(1, 2, 3))
    println(mul2_add(3, 4, 5))
    println(max3(10, 20, 15))
    println(max3(30, 10, 20))
    println(max3(5, 5, 5))
    0
