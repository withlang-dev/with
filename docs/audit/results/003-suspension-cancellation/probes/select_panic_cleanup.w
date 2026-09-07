extern fn with_ewrite(s: &str) -> Unit

async fn tick() -> i32: 1

async fn bad() -> i32:
    let _ = tick().await
    panic("select child panic")

async fn sibling() -> i32:
    defer: unsafe { with_ewrite("select sibling cleanup\n") }
    while true:
        let _ = tick().await
    0

fn main:
    let failed = bad()
    let other = sibling()
    select await biased:
        value = failed => ()
        value = other => ()
