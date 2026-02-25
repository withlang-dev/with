fn id[T](x: T) -> T =
    x

fn add_one[T](x: T) -> T =
    x + 1

fn main() -> i32 =
    let a = id(40)
    let b = add_one(1)
    assert(a + b == 42)
    0
