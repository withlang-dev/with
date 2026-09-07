use std.task.Task
use std.builtins.print_i32

extern fn with_fiber_live_fibers() -> i32
extern fn with_runtime_run_one_step() -> Unit

var AFTER: i32 = 0

async fn tick() -> i32: 1
async fn forever() -> i32:
    while true:
        let _ = tick().await
    0

async fn observe(task: Task[i32]) -> i32:
    let value = task.await
    unsafe { AFTER = AFTER + 1 }
    value

fn drive_until_done(task: &Task[i32]):
    var steps = 0
    while not task.is_done() and steps < 256:
        unsafe { with_runtime_run_one_step() }
        steps = steps + 1
    assert(task.is_done())

fn main:
    let baseline = unsafe { with_fiber_live_fibers() }
    let child = forever()
    child.cancel()
    drive_until_done(&child)
    let parent = observe(child)
    drive_until_done(&parent)
    print_i32(if parent.was_cancelled(): 1 else: 0)
    unsafe { print_i32(AFTER) }
    let _ = parent.await
    assert(unsafe { with_fiber_live_fibers() } == baseline)
    assert(parent.was_cancelled())
    unsafe { assert(AFTER == 0) }
