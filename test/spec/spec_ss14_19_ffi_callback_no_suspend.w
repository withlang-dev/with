//! check-only

extern fn c_compare(cb: fn(i32, i32) -> i32) -> i32

fn main:
    let _ = c_compare((a, b) => a - b)
