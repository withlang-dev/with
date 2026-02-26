fn main() -> i32 =
    let x = 10
    let add_x = |n| n + x
    println(add_x(5))
    println(add_x(20))

    let y = 3
    let mul_y = |n| n * y
    println(mul_y(4))
    0
