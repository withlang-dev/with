//! expect-check-fail: wrong argument type in call to 'take_i32'

fn take_i32(value: i32) -> i32: value

fn main:
    let value: i32 = 42
    let pointer: *const i32 = &value as *const i32
    take_i32(pointer)
