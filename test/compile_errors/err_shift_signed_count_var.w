//! expect-error: shift count must be unsigned integer

fn main:
    let x: u8 = 1
    let n: i32 = 5
    let _ = x << n
