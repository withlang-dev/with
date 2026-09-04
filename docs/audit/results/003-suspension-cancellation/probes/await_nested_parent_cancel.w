extern fn with_fiber_live_fibers() -> i32
extern fn with_runtime_run_one_step() -> Unit

var CLEANUPS: i32 = 0

async fn tick() -> i32: 1

async fn chain(depth: i32) -> i32:
    defer: unsafe { CLEANUPS = CLEANUPS + 1 }
    if depth == 0:
        while true:
            let _ = tick().await
        return 1
    chain(depth - 1).await

fn main:
    let baseline = unsafe { with_fiber_live_fibers() }
    let task = chain(3)
    var steps = 0
    while unsafe { with_fiber_live_fibers() } < baseline + 5 and steps < 256:
        unsafe { with_runtime_run_one_step() }
        steps = steps + 1
    assert(unsafe { with_fiber_live_fibers() } >= baseline + 5)
    task.cancel()
    task.join_cleanup()
    assert(unsafe { with_fiber_live_fibers() } == baseline)
    unsafe { assert(CLEANUPS == 4) }
    print("nested-parent-cancel-ok")
