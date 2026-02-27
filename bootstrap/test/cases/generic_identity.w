// Test generic identity function with various types
fn identity[T](x: T) -> T: x

fn main -> i32:
    println(identity(42))
    println(identity(true))
    println(identity("hello"))
