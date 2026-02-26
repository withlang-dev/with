// Test Result combinators: map, map_err, and_then, unwrap_or, is_ok, is_err

fn double(x: i32) -> i32: x * 2

fn main -> i32:
    let ok_val: Result[i32, i32] = Ok(21)
    let err_val: Result[i32, i32] = Err(42)

    // is_ok / is_err
    assert(ok_val.is_ok())
    assert(err_val.is_err())

    // unwrap_or
    assert(ok_val.unwrap_or(0) == 21)
    assert(err_val.unwrap_or(99) == 99)

    // map
    let doubled = ok_val.map(double)
    assert(doubled.unwrap_or(0) == 42)

    let err_mapped = err_val.map(double)
    assert(err_mapped.is_err())
