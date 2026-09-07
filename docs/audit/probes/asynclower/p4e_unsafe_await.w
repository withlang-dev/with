async fn ready(value: i32) -> i32:
    value

unsafe fn m -> i32:
    unsafe:
        ready(1).await
