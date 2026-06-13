//! expect-check-fail: FixedString length must be a compile-time integer constant

fn main:
    let n = 4
    let s: FixedString[n] = FixedString[4].new()
    let _ = s
