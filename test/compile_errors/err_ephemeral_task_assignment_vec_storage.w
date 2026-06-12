//! expect-check-fail: ephemeral Task cannot be stored in generic container

async fn owned_task(value: i32) -> i32:
    value

async fn borrowed_task(value: &i32) -> i32:
    *value

fn main:
    let value = 42
    var task = owned_task(1)
    task = borrowed_task(&value)
    var tasks = Vec[Task[i32]].new()
    tasks.push(task)
