use std.sync

fn acquire(lock: &Mutex[i64]) -> MutexGuard[i64]: lock.enter()

fn main:
    let lock = Mutex[i64].new(1 as i64)
    no_suspend:
        let guard = acquire(&lock)
        let _ = guard.exit()
