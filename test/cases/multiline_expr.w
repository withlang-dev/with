// Test multiline expressions
fn fibonacci(n: i32) -> i32 =
    if n <= 1: n
    else fibonacci(n - 1) + fibonacci(n - 2)

fn main() -> i32 =
    println(fibonacci(0))
    println(fibonacci(1))
    println(fibonacci(5))
    println(fibonacci(10))
    0
