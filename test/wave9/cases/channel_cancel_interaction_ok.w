// Wave 9: channel + cancel interaction should not break remaining task flow.

async fn producer(ch: i64) -> i32:
    send(ch, 10)
    send(ch, 20)
    0

async fn consumer(ch: i64) -> i32:
    recv(ch)

fn main -> i32:
    let ch = Channel(4)
    let p = producer(ch)
    let c1 = consumer(ch)
    let c2 = consumer(ch)

    c2.cancel()

    let v1 = c1.await
    let _ = p.await

    assert(v1 == 10 or v1 == 20)
    0
