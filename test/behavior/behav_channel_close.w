//! expect-stdout: ok

// D10 (decisions.md): recv() -> Option[T]. Buffered messages are delivered
// first (Some), and only a closed AND drained channel yields None.

use std.channel

async fn producer(tx: Sender[i32]) -> i32:
    tx.send(1)
    tx.send(2)
    tx.close()
    0

async fn consumer(rx: Receiver[i32]) -> i32:
    let a = rx.recv().unwrap()
    let b = rx.recv().unwrap()
    assert(rx.recv().is_none())
    assert(rx.recv().is_none())
    a + b

async fn main:
    let pair = chan[i32](8)
    let (tx, rx) = pair
    let p = producer(move tx)
    let c = consumer(move rx)
    let sum = c.await
    let _ = p.await
    assert(sum == 3)
    print("ok")
