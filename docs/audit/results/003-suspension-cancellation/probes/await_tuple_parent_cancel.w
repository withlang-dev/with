extern fn with_fiber_live_fibers() -> i32
extern fn with_runtime_run_one_step() -> Unit
use std.builtins.print_i32

async fn tick() -> i32: 1
async fn forever(value: i32) -> i32:
    while true:
        let _ = tick().await
    value

async fn parent() -> i32:
    let left = forever(1)
    let right = forever(2)
    let (a, b) = (left, right).await
    a + b

fn main:
    let baseline = unsafe { with_fiber_live_fibers() }
    let task = parent()
    var steps = 0
    while unsafe { with_fiber_live_fibers() } < baseline + 3 and steps < 128:
        unsafe { with_runtime_run_one_step() }
        steps = steps + 1
    assert(unsafe { with_fiber_live_fibers() } >= baseline + 3)
    task.cancel()
    task.join_cleanup()
    print_i32(unsafe { with_fiber_live_fibers() } - baseline)
    assert(unsafe { with_fiber_live_fibers() } == baseline)
