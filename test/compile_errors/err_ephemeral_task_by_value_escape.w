//! expect-check-fail: ephemeral Task may escape

async fn process(value: &i32) -> i32:
    *value + 1

fn ignore_task(task: Task[i32]):
    let _ = 0

fn main:
    let value = 41
    let task = process(&value)
    ignore_task(task)
