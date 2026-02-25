// Test: channels with async producer and consumer
async fn producer(ch: i64) -> i32 =
    send(ch, 10)
    send(ch, 20)
    send(ch, 30)
    0

async fn consumer(ch: i64) -> i32 =
    let a = recv(ch)
    let b = recv(ch)
    let c = recv(ch)
    a + b + c

fn main() -> i32 =
    let ch = Channel(16)

    let p = producer(ch)
    let c = consumer(ch)

    let result = c.await
    let _ = p.await

    assert(result == 60)
    0
