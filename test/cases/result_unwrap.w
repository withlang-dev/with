// Test: result unwrap_or, map_err chain
fn negate(x: i32) -> i32: 0 - x
fn double(x: i32) -> i32: x * 2

fn main -> i32:
    // unwrap_or on Ok
    let a: Result[i32, i32] = Ok(42)
    assert(a.unwrap_or(0) == 42)

    // unwrap_or on Err
    let b: Result[i32, i32] = Err(5)
    assert(b.unwrap_or(42) == 42)

    // map on Ok
    let c: Result[i32, i32] = Ok(21)
    let d = c.map(double)
    assert(d.unwrap() == 42)

    // map_err on Err then unwrap_or
    let e: Result[i32, i32] = Err(3)
    let f = e.map_err(negate)
    assert(f.is_err())
    assert(f.unwrap_or(42) == 42)

    // map_err on Ok preserves value
    let g: Result[i32, i32] = Ok(42)
    let h = g.map_err(negate)
    assert(h.unwrap() == 42)

