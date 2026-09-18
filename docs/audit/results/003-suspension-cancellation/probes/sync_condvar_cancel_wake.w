use std.sync
use std.builtins.print_i32

extern fn with_runtime_run_one_step() -> Unit

var AFTER: i32 = 0

async fn blocked(lock: &Mutex[i64], cond: &Condvar) -> i32:
    with lock.enter_mut() as mut value:
        cond.wait(lock)
        unsafe { AFTER = AFTER + 1 }
        value as i32

fn main:
    let lock = Mutex[i64].new(1 as i64)
    let cond = Condvar.new()
    let task = blocked(&lock, &cond)
    unsafe { with_runtime_run_one_step() }
    task.cancel()
    cond.notify_one()
    task.join_cleanup()
    print_i32(if task.was_cancelled(): 1 else: 0)
    unsafe { print_i32(AFTER) }
    unsafe { assert(AFTER == 0) }
