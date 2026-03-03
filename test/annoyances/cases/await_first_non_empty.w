use std.async

async fn value(v: i32) -> i32:
    v

fn main -> i32:
    let tasks = Vec.new()
    tasks.push(value(7))
    tasks.push(value(8))

    let winner = await_first(tasks)
    assert(winner == 7)
    0
