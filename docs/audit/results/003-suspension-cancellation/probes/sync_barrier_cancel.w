use std.sync

extern fn with_runtime_run_one_step() -> Unit

async fn blocked(barrier: &Barrier) -> i32:
    if barrier.wait(): 1 else: 0

fn main:
    let barrier = Barrier.new(2)
    let task = blocked(&barrier)
    unsafe { with_runtime_run_one_step() }
    task.cancel()
    task.join_cleanup()
    print("barrier-cancel-ok")
