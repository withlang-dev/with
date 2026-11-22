extern fn with_fiber_is_cancelled() -> i32
extern fn with_fiber_set_cancelled_return() -> Unit
extern fn with_fiber_yield() -> Unit

async fn waits_for_cancel() -> i32:
    while with_fiber_is_cancelled() == 0:
        with_fiber_yield()
    with_fiber_set_cancelled_return()
    7

fn main:
    let task = waits_for_cancel()
    task.cancel()
    task.join_cleanup()
    print("ok")
