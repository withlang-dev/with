//! expect-stdout: ok

// Behavior test: tail-recursive functions with accumulator pattern
// Tests: recursive function that should benefit from @[tailrec]

fn factorial(n: i32, acc: i32) -> i32:
    if n <= 1:
        acc
    else:
        factorial(n - 1, acc * n)

fn sum_to(n: i32, acc: i32) -> i32:
    if n <= 0:
        acc
    else:
        sum_to(n - 1, acc + n)

fn fib(n: i32, a: i32, b: i32) -> i32:
    if n <= 0:
        a
    else:
        fib(n - 1, b, a + b)

fn test_factorial:
    assert(factorial(1, 1) == 1)
    assert(factorial(5, 1) == 120)
    assert(factorial(6, 1) == 720)

fn test_sum:
    assert(sum_to(0, 0) == 0)
    assert(sum_to(10, 0) == 55)
    assert(sum_to(100, 0) == 5050)

fn test_fibonacci:
    assert(fib(0, 0, 1) == 0)
    assert(fib(1, 0, 1) == 1)
    assert(fib(10, 0, 1) == 55)

fn main:
    test_factorial()
    test_sum()
    test_fibonacci()
    println("ok")
