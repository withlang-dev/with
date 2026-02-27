// POSITIVE: with Form 3 — immutable value binding (§7.3)
fn compute(x: i32) -> i32: x * 2

fn main -> i32:
    let val = with compute(21) as result:
        result
    assert(val == 42)
    println("with form3 binding ok")
