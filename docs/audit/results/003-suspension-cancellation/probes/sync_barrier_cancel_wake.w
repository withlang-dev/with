use std.sync
use std.builtins.print_i32

extern fn with_runtime_run_one_step() -> Unit

var AFTER: i32 = 0

async fn blocked(barrier: &Barrier) -> i32:
    let _ = barrier.wait()
    unsafe { AFTER = AFTER + 1 }
    0

fn main:
    let barrier = Barrier.new(2)
    let task = blocked(&barrier)
    unsafe { with_runtime_run_one_step() }
    task.cancel()
    let _ = barrier.wait()
    task.join_cleanup()
    print_i32(if task.was_cancelled(): 1 else: 0)
    unsafe { print_i32(AFTER) }
    unsafe { assert(AFTER == 0) }
