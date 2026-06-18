//! expect-error: E0702

use std.sync

fn main:
    let lock = Mutex[i64].new(1 as i64)
    no_suspend:
        let guard = lock.enter()
        assert(guard.exit() == 1)
