@[no_await_guard]
type Guard {
    value: i32,
}

async fn work() -> i32:
    42

async fn helper(v: &i32) -> i32:
    let t = work()
    let x = t.await
    *v + x

async fn main:
    let held = Guard { value: 1 }
    let t = helper(&held.value)
    let value = t.await
    assert(value == 43)
