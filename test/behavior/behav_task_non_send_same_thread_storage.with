//! expect-stdout: ok

use std.rc
use std.task.Task

async fn work(owner: Rc[i32]) -> i32:
    owner.strong_count() as i32

fn main:
    let owner = Rc.new(1i32)
    let task = work(move owner)
    let tasks: List[Task[i32]] = List.new()
    tasks.push(task)
    assert(tasks.len() == 1)
    print("ok")
