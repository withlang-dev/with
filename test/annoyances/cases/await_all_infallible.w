use std.async

async fn make_value(v: i32) -> i32:
    v

fn main -> i32:
    let tasks = Vec.new()
    tasks.push(make_value(10))
    tasks.push(make_value(20))
    tasks.push(make_value(30))

    let values = await_all(tasks)
    assert(values.len() == 3)
    assert(values.get(0) == 10)
    assert(values.get(1) == 20)
    assert(values.get(2) == 30)
    0
