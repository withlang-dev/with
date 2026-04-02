//! expect-stdout: ok

async fn main:
    let x = 10
    let y = 20
    let task = async:
        x + y
    let result = task.await
    assert(result == 30)
    print("ok")
