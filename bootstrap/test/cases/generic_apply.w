fn identity[T](x: T) -> T: x

fn first[T](a: T, b: T) -> T: a

fn main -> i32:
    println(identity(42))
    println(identity(true))
    println(first(10, 20))
    println(first(100, 200))
