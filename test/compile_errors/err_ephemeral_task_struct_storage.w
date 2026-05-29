//! expect-check-fail: ephemeral Task cannot be stored in non-ephemeral struct

type TaskHolder {
    task: Task[i32],
}

async fn process(value: &i32) -> i32:
    *value

fn main:
    let value = 42
    let task = process(&value)
    let holder = TaskHolder { task: task }
    let _ = holder
