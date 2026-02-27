// Test @[tailrec] converts self-recursive calls to loops
@[tailrec]
fn factorial(n: i32, acc: i32) -> i32:
    if n <= 1: acc
    else factorial(n - 1, acc *% n)

@[tailrec]
fn sum_to(n: i64, acc: i64) -> i64:
    if n <= 0: acc
    else sum_to(n - 1, acc + n)

fn main -> i32:
    println(factorial(10, 1))
    println(sum_to(100, 0))
    // Large value that would stack overflow without TCO
    println(sum_to(1000000, 0))
