//! expect-error: task method expects zero arguments

async fn complete(value: i32) -> i32:
    value

fn main:
    let task = complete(1)
    let _ = task.was_cancelled(1)
