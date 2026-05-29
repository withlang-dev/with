//! expect-error: E0701

@[no_await_guard]
type Guard {
    value: i32,
}

async fn work() -> i32:
    42

fn helper() -> i32:
    let task = work()
    task.await

fn main:
    let held = Guard { value: 1 }
    let _ = helper()
    assert(held.value == 1)
