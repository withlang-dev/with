//! expect-stdout: ok

async fn process(value: &i32) -> i32:
    *value + 1

fn unchecked_sink(task: Task[i32]) -> Task[i32]:
    task

fn main:
    let value = 41
    let task = process(&value)
    let returned = unsafe { unchecked_sink(task) }
    returned.cancel()
    print("ok")
