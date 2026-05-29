//! expect-check-fail: ephemeral Task cannot be stored in enum payload

enum TaskSlot:
    Holding(Task[i32])

async fn process(value: &i32) -> i32:
    *value

fn main:
    let value = 42
    let task = process(&value)
    let slot = Holding(task)
    let _ = slot
