// Test recursive function for sum
fn sum(n: i32) -> i32 =
    if n <= 0: 0
    else n + sum(n - 1)

fn main() -> i32 =
    println(sum(10))
    println(sum(0))
    println(sum(100))
    0
