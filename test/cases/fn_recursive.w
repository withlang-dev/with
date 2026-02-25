// Test: mutually recursive functions
fn is_even(n: i32) -> bool =
    if n == 0 then true
    else is_odd(n - 1)

fn is_odd(n: i32) -> bool =
    if n == 0 then false
    else is_even(n - 1)

fn main() -> i32 =
    assert(is_even(0))
    assert(not is_odd(0))
    assert(is_odd(1))
    assert(is_even(2))
    assert(is_odd(3))
    assert(is_even(42))
    assert(is_odd(41))
    assert(not is_even(41))
    assert(not is_odd(42))
    0
