// Test: generic functions with multiple type params

fn first[T](a: T, b: T) -> T = a
fn second[T](a: T, b: T) -> T = b

fn max_val[T](a: T, b: T) -> T =
    if a > b then a else b

fn main() -> i32 =
    println(first(10, 20))
    println(second(10, 20))
    println(max_val(42, 17))
    println(max_val(3, 99))
    0
