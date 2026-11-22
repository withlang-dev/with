//! expect-check-fail: async scope result cannot be ephemeral

async fn work() -> i32:
    1

async fn main:
    let task = async scope s =>:
        let tracked = s.track(work())
        tracked
    let _ = task.await
