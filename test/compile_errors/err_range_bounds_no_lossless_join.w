//! expect-error: implicit integer narrowing or sign change from `u32` to `i32`

// §4.2.6: range bounds join only by a lossless widening; `i32` beside
// `u32` has none, as for an operator's operands.
fn main:
    let a: i32 = 1
    let b: u32 = 3
    for i in a..b:
        print(f"{i}")
