//! expect-error: bitwise operands with mixed signedness require explicit `as` cast

fn main:
    let a: u32 = 1
    let b: i32 = 2
    let c = a | b
    c
