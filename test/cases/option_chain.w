// Test: Option chaining and combinators
fn half(x: i32) -> ?i32 =
    if x % 2 == 0 then Some(x / 2) else None

fn main() -> i32 =
    // Test Some path
    let a = Some(10)
    let b = a ?? 0
    assert(b == 10)

    // Test None path
    let c: ?i32 = None
    let d = c ?? 42
    assert(d == 42)

    // Test try operator on Some
    let e = half(10) ?? 0
    assert(e == 5)

    // Test try operator on None
    let f = half(7) ?? 99
    assert(f == 99)

    0
