async fn ready(value: i32) -> i32:
    value

async fn m -> i32:
    loop:
        break ready(1).await
