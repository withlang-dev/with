//! expect-stdout: ok

@[tailrec]
fn is_even(n: i32) -> bool:
    if n == 0: true
    else: is_odd(n - 1)

@[tailrec]
fn is_odd(n: i32) -> bool:
    if n == 0: false
    else: is_even(n - 1)

fn main:
    assert(is_even(0))
    assert(not is_odd(0))
    assert(not is_even(1))
    assert(is_odd(1))
    assert(is_even(4))
    assert(is_odd(5))
    assert(not is_even(3))
    // Deep mutual recursion — would stack overflow without TCO
    assert(is_even(100000))
    assert(is_odd(100001))
    print("ok")
