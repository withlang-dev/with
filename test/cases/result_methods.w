// Test: Result combinator methods
fn main() -> i32 =
    // unwrap on Ok
    let a: Result[i32, i32] = Ok(42)
    let v = a.unwrap()
    assert(v == 42)

    // unwrap_or on Ok
    let b: Result[i32, i32] = Ok(10)
    let w = b.unwrap_or(99)
    assert(w == 10)

    // unwrap_or on Err
    let c: Result[i32, i32] = Err(5)
    let x = c.unwrap_or(99)
    assert(x == 99)

    // is_ok / is_err on Ok
    let d: Result[i32, i32] = Ok(1)
    assert(d.is_ok())
    assert(not d.is_err())

    // is_ok / is_err on Err
    let e: Result[i32, i32] = Err(0)
    assert(e.is_err())
    assert(not e.is_ok())

    0
