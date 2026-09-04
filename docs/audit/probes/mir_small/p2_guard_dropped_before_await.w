@[no_await_guard]
type Guard {
    value: i32,
}

async fn work() -> i32:
    42

async fn main:
    let held = Guard { value: 7 }
    let x = held.value
    drop(held)
    let t = work()
    let value = t.await
    assert(x + value == 49)
