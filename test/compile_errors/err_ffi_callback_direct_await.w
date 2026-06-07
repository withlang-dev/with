//! expect-check-fail: may_suspend in extern C callback

extern fn c_compare(cb: extern "C" fn(i32, i32) -> i32) -> i32

async fn weight(value: i32) -> i32:
    value

fn main:
    let _ = unsafe { c_compare((a, b) => weight(a).await - weight(b).await) }
