use std.sync
use std.task.Task
use std.builtins.print_i32

extern fn with_runtime_run_one_step() -> Unit

var AFTER: i32 = 0

async fn blocked(lock: &RwLock[i64]) -> i32:
    let guard = lock.enter()
    unsafe { AFTER = AFTER + 1 }
    guard.exit() as i32

fn drive_until_done(task: &Task[i32]):
    var steps = 0
    while not task.is_done() and steps < 128:
        unsafe { with_runtime_run_one_step() }
        steps = steps + 1
    assert(task.is_done())

fn main:
    let lock = RwLock[i64].new(1 as i64)
    let held = lock.enter_mut()
    let task = blocked(&lock)
    unsafe { with_runtime_run_one_step() }
    task.cancel()
    let _ = held.exit()
    drive_until_done(&task)
    unsafe { print_i32(AFTER) }
    print_i32(if task.was_cancelled(): 1 else: 0)
    let _ = task.await
    unsafe { assert(AFTER == 0) }
