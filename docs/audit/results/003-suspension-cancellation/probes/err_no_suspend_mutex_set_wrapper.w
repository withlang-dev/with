use std.sync

fn set(lock: &Mutex[i64]): lock.set(2 as i64)

fn main:
    let lock = Mutex[i64].new(1 as i64)
    no_suspend:
        set(&lock)
