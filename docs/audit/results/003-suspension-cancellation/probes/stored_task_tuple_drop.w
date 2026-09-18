use std.task.Task

async fn value(n: i32) -> i32: n

fn consume(tasks: (Task[i32], Task[i32])): ()

fn main:
    let tasks = (value(1), value(2))
    consume(tasks)
    print("stored-task-tuple")
