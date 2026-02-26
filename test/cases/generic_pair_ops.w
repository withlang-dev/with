fn swap[T](a: T, b: T) -> (T, T): (b, a)

fn main -> i32:
    let (a, b) = swap(1, 2)
    println(a)
    println(b)
    let (x, y) = swap(10, 20)
    println(x)
    println(y)
