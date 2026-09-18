async fn ready(value: i32) -> i32:
    value

async fn m -> i32:
    var x = 1
    let p = &raw mut x
    unsafe:
        *p = 2
        ready(x).await
