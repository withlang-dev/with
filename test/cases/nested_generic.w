// Test nested generic function calls
fn add[T](a: T, b: T) -> T = a + b
fn double[T](x: T) -> T = add(x, x)

fn main() -> i32 =
    println(double(5))
    println(double(21))
    0
