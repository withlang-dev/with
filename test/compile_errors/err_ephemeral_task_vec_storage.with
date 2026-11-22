//! expect-check-fail: ephemeral Task cannot be stored in generic container
use std.task.Task

async fn process(value: &i32) -> i32:
    *value

fn main:
    let value = 42
    let task = process(&value)
    var tasks = List[Task[i32]].new()
    tasks.push(task)
