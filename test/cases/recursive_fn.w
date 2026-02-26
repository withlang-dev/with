// Test recursive functions (non-tailrec)
fn fibonacci(n: i32) -> i32 =
    if n <= 1 then n
    else fibonacci(n - 1) + fibonacci(n - 2)

fn gcd(a: i32, b: i32) -> i32 =
    if b == 0 then a
    else gcd(b, a % b)

fn main() -> i32 =
    println(fibonacci(10))
    println(gcd(48, 18))
    println(gcd(100, 75))
    0
