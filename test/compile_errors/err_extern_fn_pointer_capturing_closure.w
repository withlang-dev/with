//! expect-check-fail: capturing closure cannot coerce to extern "C" fn pointer

fn main:
    let offset = 1
    let cb: extern "C" fn(i32) -> i32 = value => value + offset
    let _ = cb
