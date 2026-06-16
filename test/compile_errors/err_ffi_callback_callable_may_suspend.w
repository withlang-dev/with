//! expect-check-fail: may_suspend in extern C callback

extern fn c_run(cb: extern "C" fn() -> i32) -> i32

async fn work() -> i32:
    42

fn main:
    let cb = () =>
        let task = work()
        task.await

    let _ = unsafe { c_run(cb) }
