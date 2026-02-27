// Test: chaining Option and Result operations

fn safe_div(a: i32, b: i32) -> ?i32:
    if b == 0 then None
    else Some(a / b)

fn main -> i32:
    // Option chaining
    let x = safe_div(10, 2)
    let val = x ?? 0
    println(val)
    assert(val == 5)

    let y = safe_div(10, 0)
    let def = y ?? -1
    println(def)
    assert(def == -1)

    // Nested option with default
    let z = safe_div(100, safe_div(10, 2) ?? 1)
    println(z ?? 0)

