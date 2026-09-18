async fn ready(value: i32) -> i32:
    value

async fn m -> i32:
    no_suspend:
        let t = ready(1)
        t.await
