extern fn with_ewrite(s: &str) -> Unit

async fn bad() -> i32:
    panic("direct child panic")

async fn parent() -> i32:
    defer: unsafe { with_ewrite("direct parent cleanup\n") }
    bad().await

fn main:
    let _ = parent().await
