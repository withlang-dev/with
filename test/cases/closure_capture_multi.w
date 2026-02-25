// Test: closures capturing multiple variables from outer scope
fn apply(f: fn(i32) -> i32, x: i32) -> i32 = f(x)
fn apply2(f: fn(i32, i32) -> i32, a: i32, b: i32) -> i32 = f(a, b)

fn main() -> i32 =
    // Capture single variable
    let offset = 100
    let add_offset = |x| x + offset
    assert(add_offset(5) == 105)

    // Capture two variables
    let a = 10
    let b = 20
    let sum_with = |x| x + a + b
    assert(sum_with(5) == 35)

    // Capture three variables
    let p = 1
    let q = 2
    let r = 3
    let combined = |x| x * p + x * q + x * r
    assert(combined(10) == 60)

    // Closure passed as argument
    let scale = 5
    let scaler = |x| x * scale
    let result = apply(scaler, 8)
    assert(result == 40)

    // Lambda directly with capture
    let factor = 7
    let v = apply(|x| x * factor, 6)
    assert(v == 42)

    // Nested closure calls
    let base1 = 10
    let f1 = |x| x + base1
    let base2 = 20
    let f2 = |x| x + base2
    assert(f1(5) + f2(5) == 40)

    // Closure used multiple times
    let multiplier = 3
    let mul_fn = |x| x * multiplier
    assert(mul_fn(1) == 3)
    assert(mul_fn(5) == 15)
    assert(mul_fn(10) == 30)

    // Closure with two params
    let bias = 100
    let biased_add = |x, y| x + y + bias
    assert(biased_add(3, 7) == 110)

    println("all closure_capture_multi tests passed")
    0
