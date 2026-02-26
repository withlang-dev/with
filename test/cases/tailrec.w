// Test: @[tailrec] tail call optimization

@[tailrec]
fn factorial(n: i64, acc: i64) -> i64 =
    if n <= 1 then acc
    else factorial(n - 1, acc * n)

@[tailrec]
fn sum_to(n: i64, acc: i64) -> i64 =
    if n == 0 then acc
    else sum_to(n - 1, acc + n)

fn main() -> i32 =
    println(factorial(10, 1))
    println(sum_to(100, 0))
    // Large n to verify no stack overflow
    println(sum_to(100000, 0))
    0
