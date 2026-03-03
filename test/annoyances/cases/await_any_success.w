use std.async

async fn ok_value(v: i32) -> Result[i32, str]:
    Ok(v)

async fn err_value(msg: str) -> Result[i32, str]:
    Err(msg)

fn main -> i32:
    let tasks = Vec.new()
    tasks.push(err_value("first"))
    tasks.push(ok_value(42))
    tasks.push(err_value("third"))

    let result = await_any(tasks)
    assert(result.is_ok())
    assert(result.unwrap() == 42)
    0
