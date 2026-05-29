//! expect-stdout: ok

use std.channel

async fn producer(tx: Sender[i32]) -> i32:
    tx.send(21)
    tx.send(21)
    0

async fn consumer(rx: Receiver[i32]) -> i32:
    let a = rx.recv()
    let b = rx.recv()
    a + b

async fn main:
    let (tx, rx) = chan[i32](2)
    let p = producer(tx)
    let c = consumer(rx)
    let result = c.await
    let _ = p.await
    assert(result == 42)
    print("ok")
