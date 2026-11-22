//! expect-check-fail: non-exhaustive match: missing variant 'Err'

fn fallible(ok: bool) -> Result[i32, str]:
    if ok:
        Ok(1)
    else:
        Err("bad")

fn main:
    let value = match fallible(true):
        Ok(v) => v
    let _ = value
