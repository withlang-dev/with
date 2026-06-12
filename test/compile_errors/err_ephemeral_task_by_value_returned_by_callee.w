//! expect-check-fail: ephemeral Task may escape

async fn process(value: &i32) -> i32:
    *value + 1

fn return_task(task: Task[i32]) -> Task[i32]:
    task

fn main:
    let value = 41
    let task = process(&value)
    let escaped = return_task(task)
    escaped.await
