// Test @[must_use] attribute
// The attribute causes a warning when the return value is discarded,
// but compilation still succeeds.

@[must_use]
fn compute(x: i32) -> i32 =
    x * 2

fn main() -> i32 =
    // Using the return value is fine
    let result = compute(21)
    println(result)
    0
