//! expect-stdout: ok

use std.rc

async fn work(owner: Rc[i32]) -> i32:
    owner.strong_count() as i32

fn main:
    let owner = Rc.new(1)
    let task = work(owner)
    let tasks: Vec[Task[i32]] = Vec.new()
    tasks.push(task)
    assert(tasks.len() == 1)
    print("ok")
