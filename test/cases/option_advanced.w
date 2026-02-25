// Test: Advanced Option patterns
fn safe_div(a: i32, b: i32) -> ?i32 =
    if b == 0 then None else Some(a / b)

fn double(x: i32) -> i32 = x * 2

fn main() -> i32 =
    // Basic Some/None
    let a = safe_div(10, 2)
    assert(a.is_some())
    assert(a.unwrap_or(0) == 5)

    let b = safe_div(10, 0)
    assert(b.is_none())
    assert(b.unwrap_or(-1) == -1)

    // Map
    let c = safe_div(21, 1)
    let d = c.map(double)
    assert(d.unwrap_or(0) == 42)

    // None map produces None
    let e = safe_div(10, 0)
    let f = e.map(double)
    assert(f.is_none())

    // Default operator
    let g: ?i32 = None
    let h = g ?? 99
    assert(h == 99)

    let i: ?i32 = Some(7)
    let j = i ?? 99
    assert(j == 7)

    0
