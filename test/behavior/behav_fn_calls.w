//! expect-stdout: ok

// Tests: function call patterns — pass by value, multiple args,
//        return in different positions, call chains, higher-order

fn add(a: i32, b: i32) -> i32:
    a + b

fn sub(a: i32, b: i32) -> i32:
    a - b

fn test_basic_two_arg:
    assert(add(1, 2) == 3)
    assert(sub(10, 3) == 7)

fn test_nested_calls:
    assert(add(add(1, 2), add(3, 4)) == 10)
    assert(sub(add(10, 5), sub(8, 2)) == 9)

fn zero_args() -> i32:
    42

fn test_zero_arg_call:
    assert(zero_args() == 42)

fn five_args(a: i32, b: i32, c: i32, d: i32, e: i32) -> i32:
    a + b + c + d + e

fn test_many_args:
    assert(five_args(1, 2, 3, 4, 5) == 15)
    assert(five_args(10, 20, 30, 40, 50) == 150)

fn returns_bool(x: i32) -> bool:
    x > 0

fn returns_str(x: i32) -> str:
    if x > 0: "positive" else: "non-positive"

fn test_different_return_types:
    assert(returns_bool(5))
    assert(not returns_bool(-1))
    assert(returns_str(1) == "positive")
    assert(returns_str(0) == "non-positive")

fn apply(f: fn(i32) -> i32, x: i32) -> i32:
    f(x)

fn triple(x: i32) -> i32:
    x * 3

fn test_higher_order:
    assert(apply(triple, 10) == 30)

fn compose_add(a: i32, b: i32, c: i32) -> i32:
    add(add(a, b), c)

fn test_composition:
    assert(compose_add(1, 2, 3) == 6)

fn early_return(x: i32) -> i32:
    if x < 0:
        return -1
    if x == 0:
        return 0
    return 1

fn test_early_return:
    assert(early_return(-5) == -1)
    assert(early_return(0) == 0)
    assert(early_return(5) == 1)

fn main:
    test_basic_two_arg()
    test_nested_calls()
    test_zero_arg_call()
    test_many_args()
    test_different_return_types()
    test_higher_order()
    test_composition()
    test_early_return()
    println("ok")
