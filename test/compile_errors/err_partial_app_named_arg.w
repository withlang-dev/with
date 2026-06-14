//! expect-error: placeholder partial application does not support named arguments

fn add(a: i32, b: i32) -> i32:
    a + b

fn main:
    let f = add(a: _, b: 2)
    let _ = f(3)
