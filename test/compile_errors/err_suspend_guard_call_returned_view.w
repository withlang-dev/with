//! expect-error: E0701

@[no_await_guard]
type Guard {
    value: i32,
}

fn id_i32_ref(x: &i32) -> &i32:
    x

async fn work() -> i32:
    42

async fn main:
    let held = Guard { value: 1 }
    let view = id_i32_ref(&held.value)
    let t = work()
    let value = t.await
    assert(*view == value - 41)
