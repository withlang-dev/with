// Test generic struct returned from generic function
type Wrapper[T] = { value: T }

fn wrap[T](x: T) -> Wrapper[T]:
    Wrapper { value: x }

fn main -> i32:
    let a = wrap(42)
    println(a.value)
    let b = wrap(100)
    println(b.value)
