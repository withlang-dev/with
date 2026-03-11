//! expect-build-fail: wrong argument type

// Test: invalid cast from str to i32 is rejected at code generation.

fn main:
    let s = "hello"
    let x = s as i32
    println(int_to_string(x))
