//! expect-check-fail: manual extern function call requires unsafe context

@[effect(p: read)]
extern "C" fn read_external(p: *const i32) -> i32

fn main:
    let value = 1
    let _ = read_external(&value)
