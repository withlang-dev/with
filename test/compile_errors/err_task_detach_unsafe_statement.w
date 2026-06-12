//! expect-error: E0802: task cannot be detached safely

async fn borrow_until_done(value: &i32) -> i32:
    *value

async fn main:
    let local = 42
    borrow_until_done(&local)
    let done = 1
