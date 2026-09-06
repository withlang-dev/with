async fn ready(value: i32) -> i32:
    value

unsafe async fn m(p: *i32) -> i32:
    unsafe:
        let x = *p
        ready(x).await
