//! expect-stdout: ok

// End-to-end test: function declarations and calls
// Tests: basic fn, params, return types, recursion, multiple params

fn add(a: i32, b: i32) -> i32:
    a + b

fn square(x: i32) -> i32:
    x * x

fn noop:
    let x = 1

fn identity(x: i32) -> i32:
    x

fn max(a: i32, b: i32) -> i32:
    if a > b: a else b

fn factorial(n: i32) -> i32:
    if n <= 1:
        1
    else:
        n * factorial(n - 1)

fn fib(n: i32) -> i32:
    if n <= 1:
        n
    else:
        fib(n - 1) + fib(n - 2)

fn test_basic_calls:
    assert(add(2, 3) == 5)
    assert(add(0, 0) == 0)
    assert(add(-1, 1) == 0)
    assert(square(5) == 25)
    assert(square(0) == 0)
    assert(identity(42) == 42)

fn test_max:
    assert(max(3, 7) == 7)
    assert(max(10, 2) == 10)
    assert(max(5, 5) == 5)

fn test_recursion:
    assert(factorial(1) == 1)
    assert(factorial(5) == 120)
    assert(fib(0) == 0)
    assert(fib(1) == 1)
    assert(fib(6) == 8)
    assert(fib(10) == 55)

fn test_early_return:
    assert(early_ret(0) == -1)
    assert(early_ret(5) == 5)

fn early_ret(x: i32) -> i32:
    if x == 0:
        return -1
    x

fn main:
    test_basic_calls()
    test_max()
    test_recursion()
    test_early_return()
    noop()
    print("ok")
