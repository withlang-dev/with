use std.sync

extern fn with_runtime_run_one_step() -> Unit

async fn blocked(lock: &Mutex[i64], cond: &Condvar) -> i32:
    with lock.enter_mut() as mut value:
        cond.wait(lock)
        value as i32

fn main:
    let lock = Mutex[i64].new(1 as i64)
    let cond = Condvar.new()
    let task = blocked(&lock, &cond)
    unsafe { with_runtime_run_one_step() }
    task.cancel()
    task.join_cleanup()
    print("condvar-cancel-ok")
