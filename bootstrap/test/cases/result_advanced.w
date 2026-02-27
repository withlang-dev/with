// Test: Advanced Result patterns
fn parse_positive(x: i32) -> Result[i32, i32]:
    if x > 0 then Ok(x) else Err(-1)

fn double(x: i32) -> i32: x * 2

fn main -> i32:
    // Basic Ok/Err
    let a = parse_positive(21)
    assert(a.is_ok())
    assert(a.unwrap_or(0) == 21)

    let b = parse_positive(-5)
    assert(b.is_err())
    assert(b.unwrap_or(0) == 0)

    // Map
    let c = parse_positive(21)
    let d = c.map(double)
    assert(d.unwrap_or(0) == 42)

    // Err map does nothing
    let e = parse_positive(-5)
    let f = e.map(double)
    assert(f.is_err())

    // Default operator
    let g: Result[i32, i32] = Err(0)
    let h = g ?? 99
    assert(h == 99)

    let i: Result[i32, i32] = Ok(7)
    let j = i ?? 99
    assert(j == 7)

