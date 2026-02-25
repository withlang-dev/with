// Test: generic function calling another generic function
fn id[T](x: T) -> T =
    x

fn apply_id[T](x: T) -> T =
    id(x)

fn add_then_id[T](x: T, y: T) -> T =
    id(x + y)

fn main() -> i32 =
    let a = apply_id(20)
    let b = apply_id(22)
    assert(a + b == 42)
    let c = add_then_id(10, 32)
    assert(c == 42)
    0
