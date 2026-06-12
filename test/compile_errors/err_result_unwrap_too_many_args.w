//! expect-check-fail: Result.unwrap() expects no arguments

fn main:
    let r: Result[i32, str] = Ok(1)
    let _ = r.unwrap("nope")
