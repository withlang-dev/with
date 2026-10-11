//! expect-stdout: ok

// D10 (decisions.md): `for msg in rx:` is the blessed worker loop — it
// receives until the channel is closed and drained, then falls out with
// zero ceremony. break and continue behave like any loop.

use std.channel

async fn producer(tx: Sender[i32]) -> i32:
    tx.send(1)
    tx.send(2)
    tx.send(3)
    tx.send(4)
    tx.close()
    0

async fn consumer(rx: Receiver[i32]) -> i32:
    var sum: i32 = 0
    for msg in rx:
        if msg == 2:
            continue
        sum = sum + msg
    sum

async fn breaker(rx: Receiver[i32]) -> i32:
    var seen: i32 = 0
    for msg in rx:
        seen = seen + msg
        if seen >= 3:
            break
    seen

async fn main:
    let (tx, rx) = chan[i32](8)
    let p = producer(move tx)
    let c = consumer(move rx)
    let total = c.await
    let _ = p.await
    assert(total == 8)

    let (tx2, rx2) = chan[i32](8)
    let p2 = producer(move tx2)
    let b = breaker(move rx2)
    let partial = b.await
    let _ = p2.await
    assert(partial == 3)
    print("ok")
