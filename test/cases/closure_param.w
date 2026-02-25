// Test: closures (capturing and non-capturing) passed as function parameters
fn apply(f: fn(i32) -> i32, x: i32) -> i32 =
    f(x)

fn double(x: i32) -> i32 = x * 2

fn main() -> i32 =
    // Non-capturing closure as param
    let inc = |x| x + 1
    let r1 = apply(inc, 10)
    assert(r1 == 11)

    // Named function as param (wrapped as fat pointer)
    let r2 = apply(double, 21)
    assert(r2 == 42)

    // Capturing closure as param
    let offset = 100
    let add_offset = |x| x + offset
    let r3 = apply(add_offset, 5)
    assert(r3 == 105)

    // Lambda directly as param
    let r4 = apply(|x| x * x, 7)
    assert(r4 == 49)

    0
