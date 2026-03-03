use std.async

async fn ok_value(v: i32) -> Result[i32, i32]:
    Ok(v)

async fn err_value(v: i32) -> Result[i32, i32]:
    Err(v)

fn main -> i32:
    let tasks = Vec.new()
    tasks.push(ok_value(5))
    tasks.push(err_value(7))
    tasks.push(ok_value(9))

    let settled = await_settled(tasks)
    assert(settled.len() == 3)
    assert(settled.get(0).is_ok())
    assert(settled.get(0).unwrap() == 5)
    assert(settled.get(1).is_err())
    assert(settled.get(1).err().unwrap() == 7)
    assert(settled.get(2).is_ok())
    assert(settled.get(2).unwrap() == 9)
    0
