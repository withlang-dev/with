use std.task.Task

async fn work() -> i32: 1
fn cleanup(task: Task[i32]): task.join_cleanup()

fn main:
    let task = work()
    no_suspend:
        cleanup(task)
