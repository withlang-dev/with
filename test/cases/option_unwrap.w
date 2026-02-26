// Test: option unwrap_or, map, and_then chaining
fn double(x: i32) -> i32: x * 2

fn safe_half(x: i32) -> ?i32:
    if x % 2 == 0 then Some(x / 2) else None

fn main -> i32:
    // map then unwrap_or
    let a: ?i32 = Some(21)
    let b = a.map(double)
    assert(b.unwrap_or(0) == 42)

    // map on None then unwrap_or
    let c: ?i32 = None
    let d = c.map(double)
    assert(d.unwrap_or(99) == 99)

    // and_then chaining
    let e: ?i32 = Some(84)
    let f = e.and_then(safe_half)
    assert(f.is_some())
    assert(f.unwrap() == 42)

    // and_then returning None
    let g: ?i32 = Some(7)
    let h = g.and_then(safe_half)
    assert(h.is_none())
    assert(h.unwrap_or(0) == 0)

