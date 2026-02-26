// Test: Option/Result combinator methods
fn main -> i32:
    // unwrap on Some
    let a: ?i32 = Some(42)
    let v = a.unwrap()
    assert(v == 42)

    // unwrap_or on Some
    let b: ?i32 = Some(10)
    let w = b.unwrap_or(99)
    assert(w == 10)

    // unwrap_or on None
    let c: ?i32 = None
    let x = c.unwrap_or(99)
    assert(x == 99)

    // is_some / is_none on Some
    let d: ?i32 = Some(1)
    assert(d.is_some())
    assert(not d.is_none())

    // is_some / is_none on None
    let e: ?i32 = None
    assert(e.is_none())
    assert(not e.is_some())

