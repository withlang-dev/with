fn is_valid(x: i32) -> bool:
    x > 0 and x < 100

fn either(a: bool, b: bool) -> bool:
    a or b

fn main -> i32:
    println(is_valid(50))
    println(is_valid(-1))
    println(is_valid(100))
    println(either(true, false))
    println(either(false, false))
    println(not true)
    println(not false)
