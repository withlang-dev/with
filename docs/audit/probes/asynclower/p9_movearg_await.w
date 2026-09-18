async fn ready(value: i32) -> i32:
    value

fn consume(x: i32) -> i32:
    x

async fn m -> i32:
    consume(move ready(1).await)
