extern fn with_fiber_live_fibers() -> i32
extern fn with_runtime_run_one_step() -> Unit
use std.builtins.print_i32

var AFTER: i32 = 0

async fn tick() -> i32: 1

fn wait_vec() -> Vec[i32]:
    while true:
        let _ = tick().await
    Vec[i32].new()

async fn parent() -> i32:
    let _ = wait_vec()
    unsafe { AFTER = AFTER + 1 }
    0

fn main:
    let baseline = unsafe { with_fiber_live_fibers() }
    let task = parent()
    var steps = 0
    while unsafe { with_fiber_live_fibers() } < baseline + 2 and steps < 128:
        unsafe { with_runtime_run_one_step() }
        steps = steps + 1
    assert(unsafe { with_fiber_live_fibers() } >= baseline + 2)
    task.cancel()
    task.join_cleanup()
    assert(unsafe { with_fiber_live_fibers() } == baseline)
    unsafe { print_i32(AFTER) }
    unsafe { assert(AFTER == 0) }
