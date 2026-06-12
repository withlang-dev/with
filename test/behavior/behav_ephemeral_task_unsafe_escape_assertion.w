//! expect-stdout: ok

async fn process(value: &i32) -> i32:
    *value + 1

fn unchecked_sink(task: Task[i32]):
    let _ = task

fn main:
    let value = 41
    let task = process(&value)
    unsafe { unchecked_sink(task) }
    print("ok")
