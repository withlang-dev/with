fn first[T](a: T, b: T) -> T:
    a

fn second[T](a: T, b: T) -> T:
    b

fn main -> i32:
    let a = first(42, 99)
    let b = second(10, 0)
    assert(a + b == 42)
