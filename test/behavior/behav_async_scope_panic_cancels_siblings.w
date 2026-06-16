//! expect-exit: 134
//! expect-stderr: sibling cleanup
//! expect-stderr: scope child panic

extern fn with_ewrite(s: str) -> Unit

async fn tick() -> i32:
    1

async fn sibling() -> i32:
    defer: unsafe { with_ewrite("sibling cleanup\n") }
    while true:
        let _ = tick().await
    0

async fn panics_in_scope() -> i32:
    let _ = tick().await
    panic("scope child panic")

async fn parent() -> i32:
    async scope s =>:
        s.track(sibling())
        s.track(panics_in_scope())
        let _ = tick().await
        let _ = tick().await
        let _ = tick().await
        0

fn main:
    let _ = parent().await
