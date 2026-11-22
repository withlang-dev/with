//! expect-error: E0702

async fn work() -> i32:
    42

fn helper() -> i32:
    let task = work()
    task.await

fn main:
    no_suspend:
        let value = helper()
        assert(value == 42)
