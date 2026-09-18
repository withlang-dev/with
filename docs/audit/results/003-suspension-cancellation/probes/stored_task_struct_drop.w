use std.task.Task

type Holder { task: Task[i32] }

async fn value() -> i32: 1

fn main:
    let holder = Holder { task: value() }
    print("stored-task-struct")
