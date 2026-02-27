// Test: Generic functions with structs
type Box = { value: i32 }

fn wrap(x: i32) -> Box:
    Box { value: x }

fn unwrap(b: Box) -> i32:
    b.value

fn identity[T](x: T) -> T: x

fn main -> i32:
    let b = wrap(42)
    assert(unwrap(b) == 42)
    assert(identity(42) == 42)
    assert(identity(true))
