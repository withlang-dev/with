// Test: function pointers as values and parameters
fn apply(x: i32, f: fn(i32) -> i32) -> i32 =
    f(x)

fn double(x: i32) -> i32 = x * 2
fn negate(x: i32) -> i32 = 0 - x

fn main() -> i32 =
    let r1 = apply(21, double)
    assert(r1 == 42)
    let r2 = apply(5, negate)
    assert(r2 == -5)
    // Function as first-class value
    let f = double
    let r3 = f(10)
    assert(r3 == 20)
    0
