//! expect-error: E0702

async fn work() -> i32:
    42

fn main:
    no_suspend:
        let task = work()
        let value = task.await
        assert(value == 42)
