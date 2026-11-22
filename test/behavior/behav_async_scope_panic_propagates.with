//! expect-exit: 134
//! expect-stderr: scope child panic

async fn tick() -> i32:
    1

async fn panics_in_scope() -> i32:
    let _ = tick().await
    panic("scope child panic")

async fn parent() -> i32:
    async scope s =>:
        s.track(panics_in_scope())
        let _ = tick().await
        let _ = tick().await
        let _ = tick().await
        0

fn main:
    let _ = parent().await
