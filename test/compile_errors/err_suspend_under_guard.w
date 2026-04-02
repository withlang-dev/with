//! expect-error: E0701

async fn work() -> i32:
    42

async fn main:
    let lock_guard = 1
    let t = work()
    t.await
