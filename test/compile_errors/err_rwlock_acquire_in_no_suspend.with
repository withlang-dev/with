//! expect-error: E0702

use std.sync

fn main:
    let lock = RwLock[i64].new(1 as i64)
    no_suspend:
        let guard = lock.enter_mut()
        assert(guard.exit() == 1)
