//! expect-check-fail: async fiber/task creation allocates here

async fn work() -> i32:
    1

@[no_alloc]
fn main:
    let _task = work()

