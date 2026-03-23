//! expect-stdout: ok

// Tests: function calls, recursion, multiple return paths,
//        functions as values, nested calls, void functions

fn add(a: i32, b: i32) -> i32:
    a + b

fn sub(a: i32, b: i32) -> i32:
    a - b

fn test_basic_calls:
    assert(add(3, 4) == 7)
    assert(sub(10, 3) == 7)
    assert(add(0, 0) == 0)
    assert(sub(0, 5) == -5)

fn test_nested_calls:
    assert(add(add(1, 2), add(3, 4)) == 10)
    assert(sub(add(10, 5), sub(8, 2)) == 9)

fn factorial(n: i32) -> i32:
    if n <= 1:
        return 1
    n * factorial(n - 1)

fn test_recursion:
    assert(factorial(0) == 1)
    assert(factorial(1) == 1)
    assert(factorial(5) == 120)
    assert(factorial(10) == 3628800)

fn fib(n: i32) -> i32:
    if n <= 1:
        return n
    fib(n - 1) + fib(n - 2)

fn test_fibonacci:
    assert(fib(0) == 0)
    assert(fib(1) == 1)
    assert(fib(2) == 1)
    assert(fib(3) == 2)
    assert(fib(10) == 55)

fn max3(a: i32, b: i32, c: i32) -> i32:
    var m = a
    if b > m:
        m = b
    if c > m:
        m = c
    m

fn test_multiple_params:
    assert(max3(1, 2, 3) == 3)
    assert(max3(3, 2, 1) == 3)
    assert(max3(2, 3, 1) == 3)
    assert(max3(5, 5, 5) == 5)

fn clamp(val: i32, lo: i32, hi: i32) -> i32:
    if val < lo:
        return lo
    if val > hi:
        return hi
    val

fn test_multiple_returns:
    assert(clamp(5, 0, 10) == 5)
    assert(clamp(-5, 0, 10) == 0)
    assert(clamp(15, 0, 10) == 10)

var g_side_effect: i32 = 0

fn side_effect_fn(x: i32) -> i32:
    g_side_effect = g_side_effect + 1
    x

fn test_side_effects:
    g_side_effect = 0
    let _ = side_effect_fn(1)
    let _ = side_effect_fn(2)
    let _ = side_effect_fn(3)
    assert(g_side_effect == 3)

fn void_fn(x: *mut i32):
    unsafe: *x = 42

fn test_void_function:
    var val = 0
    void_fn(&mut val)
    assert(val == 42)

fn gcd(a: i32, b: i32) -> i32:
    var x = a
    var y = b
    while y != 0:
        let t = y
        y = x % y
        x = t
    x

fn test_gcd:
    assert(gcd(12, 8) == 4)
    assert(gcd(100, 75) == 25)
    assert(gcd(17, 13) == 1)
    assert(gcd(0, 5) == 5)

fn main:
    test_basic_calls()
    test_nested_calls()
    test_recursion()
    test_fibonacci()
    test_multiple_params()
    test_multiple_returns()
    test_side_effects()
    test_void_function()
    test_gcd()
    println("ok")
