//! expect-stdout: ok

fn add(a: i32, b: i32) -> i32:
    a + b

fn mul(a: i32, b: i32) -> i32:
    a * b

fn apply(f: fn(i32) -> i32, x: i32) -> i32:
    f(x)

fn test_basic_partial:
    let add5 = add(5, _)
    assert(add5(3) == 8)
    assert(add5(10) == 15)

fn test_partial_first_arg:
    let double = mul(2, _)
    assert(double(7) == 14)

fn test_partial_with_apply:
    let add10 = add(10, _)
    assert(apply(add10, 5) == 15)

fn main:
    test_basic_partial()
    test_partial_first_arg()
    test_partial_with_apply()
    print("ok")
