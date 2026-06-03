//! expect-stdout: ok

async fn work(value: i32) -> i32:
    value + 1

fn add_one(value: i32) -> i32:
    value + 1

fn make_task(value: i32) -> Task[i32]:
    work(value)

fn main:
    let from_colon = no_suspend:
        let value = add_one(40)
        value + 1
    assert(from_colon == 42)

    let from_inline_colon = no_suspend: add_one(41)
    assert(from_inline_colon == 42)

    let from_braces = no_suspend { add_one(41) }
    assert(from_braces == 42)

    let task = no_suspend:
        make_task(41)
    assert(task.await == 42)

    print("ok")
