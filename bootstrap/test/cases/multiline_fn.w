fn factorial(n: i32) -> i32:
    if n <= 1:
        1
    else
        n * factorial(n - 1)

fn collatz_steps(n: i32) -> i32:
    if n == 1: 0
    else if n % 2 == 0: 1 + collatz_steps(n / 2)
    else 1 + collatz_steps(3 * n + 1)

fn main -> i32:
    println(factorial(5))
    println(factorial(10))
    println(collatz_steps(6))
