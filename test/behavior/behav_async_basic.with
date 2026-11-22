//! expect-stdout: ok

async fn double(x: i32) -> i32:
    x * 2

async fn main:
    let task = double(21)
    let result = task.await
    assert(result == 42)
    print("ok")
