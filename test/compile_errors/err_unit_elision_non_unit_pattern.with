//! expect-check-fail: variant pattern 'Ok' expects 1 payload pattern(s), found 0

fn main:
    let r: Result[i32, str] = Ok(1)
    match r:
        Ok() => ()
        Err(_) => ()
