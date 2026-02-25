// Test: closures capturing variables in different scopes
fn apply(f: fn(i32) -> i32, x: i32) -> i32 =
    f(x)

fn main() -> i32 =
    // capture a let binding
    let base = 100
    let add_base = |x| x + base
    assert(add_base(5) == 105)
    assert(add_base(42) == 142)

    // capture multiple values
    let a = 10
    let b = 20
    let combine = |x| x + a + b
    assert(combine(0) == 30)
    assert(combine(12) == 42)

    // pass capturing closure to function
    let scale = 3
    let mul_scale = |x| x * scale
    let result = apply(mul_scale, 7)
    assert(result == 21)

    // nested capture: closure uses outer captured value
    let factor = 5
    let multiplier = |x| x * factor
    let r1 = apply(multiplier, 8)
    assert(r1 == 40)

    // non-capturing closure for comparison
    let plain = |x| x + 1
    assert(plain(9) == 10)

    println("all closure capture mut tests passed")
    0
