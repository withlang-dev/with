use std.sync

fn acquire(lock: &RwLock[i64]) -> RwWriteGuard[i64]: lock.enter_mut()

fn main:
    let lock = RwLock[i64].new(1 as i64)
    no_suspend:
        let guard = acquire(&lock)
        let _ = guard.exit()
