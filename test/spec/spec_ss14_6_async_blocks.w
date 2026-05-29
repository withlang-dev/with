//! expect-stdout: ok

async fn compute(id: i32) -> i32:
    id + 1

fn test_async_block_returns_task:
    let task = async:
        let value = compute(41).await
        value
    assert(task.await == 42)

fn test_async_block_captures_variables:
    let x = 10
    let y = 32
    let task = async:
        x + y
    assert(task.await == 42)

async fn tracked_async_blocks:
    async scope s =>:
        s.track(async:
            let _ = compute(20).await
        )
        s.track(async:
            let _ = compute(21).await
        )

fn main:
    test_async_block_returns_task()
    test_async_block_captures_variables()
    tracked_async_blocks().await
    print("ok")
