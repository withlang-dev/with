use std.sync

fn write(lock: &RwLock[i64]): lock.write(2 as i64)

fn main:
    let lock = RwLock[i64].new(1 as i64)
    no_suspend:
        write(&lock)
