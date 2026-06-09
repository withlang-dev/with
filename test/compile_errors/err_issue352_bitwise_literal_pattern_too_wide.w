//! expect-error: integer literal bit pattern does not fit expected type

fn main:
    let x: i8 = -1
    let y = x & 0x1ff
    y
