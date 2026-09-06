use std.task.Task

extern fn with_fiber_live_fibers() -> i32
extern fn with_runtime_run_one_step() -> Unit

async fn tick() -> i32: 1

async fn forever_copy() -> i32:
    while true:
        let _ = tick().await
    1

async fn forever_unit():
    while true:
        let _ = tick().await

async fn parent_copy() -> i32: forever_copy().await

async fn parent_unit() -> i32:
    forever_unit().await
    0

fn drive_until_live(target: i32):
    var steps = 0
    while unsafe { with_fiber_live_fibers() } < target and steps < 128:
        unsafe { with_runtime_run_one_step() }
        steps = steps + 1
    assert(unsafe { with_fiber_live_fibers() } >= target)

fn cancel_case(task: Task[i32]):
    let baseline = unsafe { with_fiber_live_fibers() } - 1
    drive_until_live(baseline + 2)
    task.cancel()
    task.join_cleanup()
    assert(unsafe { with_fiber_live_fibers() } == baseline)

fn main:
    cancel_case(parent_copy())
    cancel_case(parent_unit())
    print("await-copy-unit-cancel-ok")
