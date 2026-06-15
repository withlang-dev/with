//! expect-error: channel send requires Send value

use std.rc

async fn work(owner: Rc[i32]) -> i32:
    owner.strong_count() as i32

fn main:
    let owner = Rc.new(1)
    let task = work(owner)
    let (tx, _rx) = chan[Task[i32]](1)
    tx.send(task)
