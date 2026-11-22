//! expect-check-fail: track() is only available inside async scope

async fn work() -> i32:
    1

async fn main:
    scope s =>:
        s.track(work())
