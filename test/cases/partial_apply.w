// Test: partial application with _ placeholder
fn add(a: i32, b: i32) -> i32 = a + b
fn mul(a: i32, b: i32) -> i32 = a * b

fn apply(f: fn(i32) -> i32, x: i32) -> i32 = f(x)

fn main() -> i32 =
    // Partial application: add(5, _) creates a closure |x| add(5, x)
    let add5 = add(5, _)
    assert(add5(10) == 15)
    assert(add5(20) == 25)

    // First argument placeholder
    let double = mul(_, 2)
    assert(double(7) == 14)

    // Use with higher-order functions
    let result = apply(add(100, _), 42)
    assert(result == 142)

    println("all partial apply tests passed")
    0
