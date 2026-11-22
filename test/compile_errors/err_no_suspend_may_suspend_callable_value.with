//! expect-error: E0702

async fn work() -> i32:
    42

fn main:
    let cb = () =>
        let task = work()
        task.await

    no_suspend:
        let _ = cb()
