//! expect-error: constant arithmetic overflows `u32`

// #1820: `0 - 1` in a u32 context wraps below zero, a checked-arithmetic
// panic whose value is known at compile time.
let MASK: u32 = 0 - 1

fn main:
    print(f"{MASK}")
