use std.async

async fn value(v: i32) -> i32:
    v

fn main -> i32:
    let tasks = Vec.new()
    tasks.push(value(1))
    tasks.push(value(2))
    tasks.push(value(3))

    let limited = with_concurrency(tasks, 2)
    let values = await_all(limited)
    assert(values.len() == 3)
    assert(values.get(0) == 1)
    assert(values.get(1) == 2)
    assert(values.get(2) == 3)
    0
