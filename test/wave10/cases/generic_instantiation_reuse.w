fn id[T](x: T) -> T:
    x

fn main -> i32:
    let a = id(1)
    let b = id(2)
    let c = id(true)
    let _sum = a + b
    if c then 0 else 1
