//! expect-error: integer overflow in comptime

const X: i32 = 2147483647 + 1

fn main:
    let _ = X
