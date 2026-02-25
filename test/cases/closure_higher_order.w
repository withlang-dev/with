// Test: Higher-order functions with closures
fn apply(f: fn(i32) -> i32, x: i32) -> i32 =
    f(x)

fn double(x: i32) -> i32 = x * 2
fn square(x: i32) -> i32 = x * x

fn main() -> i32 =
    assert(apply(double, 21) == 42)
    assert(apply(square, 6) == 36)
    0
