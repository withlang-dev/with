//! expect-check-fail: expected expression

async fn work() -> i32:
    1

fn main:
    spawn work()
