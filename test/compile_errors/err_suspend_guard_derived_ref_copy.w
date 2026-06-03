//! expect-error: E0701

@[no_await_guard]
type Guard {
    value: i32,
}

async fn work() -> i32:
    42

async fn main:
    let held = Guard { value: 1 }
    let view = &held.value
    let view2 = view
    let t = work()
    let value = t.await
    assert(*view2 == value - 41)
