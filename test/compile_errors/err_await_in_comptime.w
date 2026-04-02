//! expect-error: await is not allowed in comptime

async fn compute() -> i32:
    42

comptime fn bad() -> i32:
    let t = compute()
    t.await
