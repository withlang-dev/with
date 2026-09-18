@[no_await_guard]
type Guard {
    value: i32,
}

async fn work() -> i32:
    42

async fn main:
    let held = Guard { value: 1 }
    let r = &held
    let t = (r, 42)
    let task = work()
    let value = task.await
    let (rr, n) = t
    assert(rr.value == value - 41)
    assert(n == 42)
