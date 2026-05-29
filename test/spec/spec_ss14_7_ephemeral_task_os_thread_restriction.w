//! expect-stdout: ok

async fn process(value: &i32) -> i32:
    *value + 1

async fn main:
    let data = 41
    let task = process(&data)
    assert(task.await == 42)
    print("ok")
