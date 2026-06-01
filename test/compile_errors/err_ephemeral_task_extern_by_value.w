//! expect-check-fail: ephemeral Task cannot be passed by value to extern function

extern fn store_task(task: Task[i32]) -> void

async fn process(value: &i32) -> i32:
    *value

fn main:
    let value = 42
    let task = process(&value)
    unsafe { store_task(task) }
