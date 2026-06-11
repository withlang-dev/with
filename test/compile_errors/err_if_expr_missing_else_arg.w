//! expect-check-fail: if expression requires an else branch unless the then branch diverges

fn take_i32(x: i32) -> i32:
    x

fn main:
    let _x = take_i32(if true: 5)
