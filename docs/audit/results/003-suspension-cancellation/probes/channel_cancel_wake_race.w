use std.channel
use std.task.Task
use std.builtins.print_i32

extern fn with_runtime_run_one_step() -> Unit

var AFTER: i32 = 0

async fn blocked(rx: Receiver[i32]) -> i32:
    let _ = rx.recv()
    unsafe { AFTER = AFTER + 1 }
    0

fn drive_until_done(task: &Task[i32]):
    var steps = 0
    while not task.is_done() and steps < 128:
        unsafe { with_runtime_run_one_step() }
        steps = steps + 1
    assert(task.is_done())

fn main:
    unsafe { AFTER = 0 }
    let (tx, rx) = chan[i32](1)
    let task = blocked(rx)
    unsafe { with_runtime_run_one_step() }
    task.cancel()
    tx.close()
    drive_until_done(&task)
    unsafe { print_i32(AFTER) }
    print_i32(if task.was_cancelled(): 1 else: 0)
    let _ = task.await
    unsafe { assert(AFTER == 0) }
