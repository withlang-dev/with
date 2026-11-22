//! expect-stdout: ok

async fn fetch(n: i32) -> Result[i32, str]:
    n + 1

async fn double(n: i32) -> i32:
    n * 2

async fn plus_one(n: i32) -> Result[i32, str]:
    n + 1

async fn await_with_question -> Result[i32, str]:
    let v = plus_one(40).await?
    v + 1

async fn await_stored_task -> i32:
    let task = double(21)
    task.await

async fn main:
    let direct = fetch(1).await.unwrap()
    assert(direct == 2)

    let chained = await_with_question().await.unwrap()
    assert(chained == 42)

    let stored = await_stored_task().await
    assert(stored == 42)

    print("ok")
