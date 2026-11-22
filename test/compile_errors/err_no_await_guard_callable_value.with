//! expect-error: E0701

@[no_await_guard]
type Guard {
    value: i32,
}

async fn work() -> i32:
    42

fn main:
    let held = Guard { value: 1 }
    let cb = () =>
        let task = work()
        task.await

    let _ = cb()
    assert(held.value == 1)
