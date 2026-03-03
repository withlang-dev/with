use std.async

async fn err_value(v: i32) -> Result[i32, i32]:
    Err(v)

fn main -> i32:
    let tasks = Vec.new()
    tasks.push(err_value(11))
    tasks.push(err_value(22))
    tasks.push(err_value(33))

    let result = await_any(tasks)
    assert(result.is_err())
    let errors = result.err().unwrap()
    assert(errors.len() == 3)
    assert(errors.get(0) == 11)
    assert(errors.get(1) == 22)
    assert(errors.get(2) == 33)
    0
