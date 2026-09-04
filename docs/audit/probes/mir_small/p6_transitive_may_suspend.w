@[no_await_guard]
type Guard {
    value: i32,
}

async fn inner() -> i32:
    42

async fn outer() -> i32:
    let t = inner()
    t.await

async fn main:
    let held = Guard { value: 1 }
    let t = outer()
    let value = t.await
    assert(held.value == value - 41)
