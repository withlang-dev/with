//! expect-error: E0702

use std.sync

fn main:
    let lock = Mutex[i64].new(0 as i64)
    let cond = Condvar.new()
    no_suspend:
        cond.wait(&lock)
