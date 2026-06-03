//! expect-error: E0701

use std.sync

async fn work() -> i32:
    42

async fn main:
    let lock = mutex_new(1)
    let task = work()
    with lock.enter() as data:
        assert(data == 1)
        task.await
