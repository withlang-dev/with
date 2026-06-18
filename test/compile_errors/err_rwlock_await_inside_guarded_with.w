//! expect-error: E0701

use std.sync

async fn work() -> i32:
    42

async fn main:
    let lock = RwLock[i64].new(1 as i64)
    let task = work()
    with lock.enter() as data:
        assert(*data == 1)
        task.await
