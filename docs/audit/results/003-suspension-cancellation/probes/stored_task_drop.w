use std.task.Task

async fn value(n: i32) -> i32: n

fn main:
    var tasks = Vec[Task[i32]].new()
    tasks.push(value(1))
    tasks.push(value(2))
    print("stored-task-drop")
