use std.task.Task

async fn value() -> i32: 1

fn main:
    let task: Option[Task[i32]] = Some(value())
    print("stored-task-option")
