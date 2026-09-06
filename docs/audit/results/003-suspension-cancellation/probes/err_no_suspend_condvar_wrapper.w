use std.sync

fn wait(cond: &Condvar, lock: &Mutex[i64]): cond.wait(lock)

fn main:
    let lock = Mutex[i64].new(1 as i64)
    let cond = Condvar.new()
    no_suspend:
        wait(&cond, &lock)
