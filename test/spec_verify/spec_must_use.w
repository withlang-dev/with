// POSITIVE: @[must_use] warning on discarded return value
@[must_use]
fn compute(x: i32) -> i32:
    x * 2

fn main -> i32:
    // Using the return value — no warning
    let result = compute(21)
    assert(result == 42)
    println("must_use ok")
