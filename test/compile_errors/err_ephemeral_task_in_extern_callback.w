//! expect-check-fail: ephemeral Task cannot be created in extern C callback

extern fn c_run(cb: extern "C" fn() -> i32) -> i32

async fn process(value: &i32) -> i32:
    *value + 1

fn callback() -> i32:
    let data = 41
    let task = process(&data)
    0

fn main:
    let _ = unsafe { c_run(callback) }
