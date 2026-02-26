// Test generic function with pair operations
fn first(a: i32, b: i32) -> i32 = a
fn second(a: i32, b: i32) -> i32 = b

fn main() -> i32 =
    println(first(10, 20))
    println(second(10, 20))
    let (a, b) = (42, 58)
    println(a)
    println(b)
    0
