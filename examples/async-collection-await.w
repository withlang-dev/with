use std.task

async fn fetch_user(id: i32) -> Result[i32, str]:
    if id > 0 then Ok(id * 10)
    else Err("invalid id")

fn main -> i32:
    let ids = Vec.of(1, 2, 3)
    let tasks = Vec.new()
    for id in ids:
        tasks.push(fetch_user(id))

    let users = await_all(tasks)
    assert(users.is_ok())
    assert(users.unwrap().len() == 3)
    0
