//! expect-exit: 134
//! expect-stdout: done

// Awaiting a panicking task reports the failure through the async runtime.

async fn bad() -> i32:
    assert(false)
    0

async fn main:
    print("done")
    let _ = bad().await
