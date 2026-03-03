use std.async

async fn ok_value(v: i32) -> Result[i32, i32]:
    Ok(v)

async fn err_value(code: i32) -> Result[i32, i32]:
    Err(code)

fn main -> i32:
    let tasks = Vec.new()
    tasks.push(ok_value(1))
    tasks.push(err_value(99))
    tasks.push(ok_value(3))

    let result = await_all(tasks)
    assert(result.is_err())
    assert(result.err().unwrap() == 99)
    0
