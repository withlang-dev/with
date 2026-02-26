// Test: tailrec fibonacci with accumulator
@[tailrec]
fn fib(n: i64, a: i64, b: i64) -> i64:
    if n == 0 then a
    else fib(n - 1, b, a + b)

fn main -> i32:
    println(fib(0, 0, 1))
    println(fib(1, 0, 1))
    println(fib(10, 0, 1))
    println(fib(20, 0, 1))
    println(fib(50, 0, 1))
