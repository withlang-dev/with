fn id[T](x: T) -> T:
    x

fn main -> i32:
    let a = id(42)
    assert(a == 42)
