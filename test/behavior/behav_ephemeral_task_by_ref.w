//! expect-stdout: ok

async fn process(value: &i32) -> i32:
    *value + 1

fn observe_task(task: &Task[i32]) -> i32:
    1

fn main:
    let value = 41
    let task = process(&value)
    assert(observe_task(&task) == 1)
    assert(task.await == 42)
    print("ok")
