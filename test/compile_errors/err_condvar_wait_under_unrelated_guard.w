//! expect-error: E0701

use std.sync

fn main:
    let lock = Mutex[i64].new(0 as i64)
    let other = Mutex[i64].new(1 as i64)
    let cond = Condvar.new()
    with other.enter() as value:
        let _ = *value
        cond.wait(&lock)
