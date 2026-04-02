//! expect-stdout: ok

use std.channel

async fn producer(tx: Sender[i32]) -> i32:
    tx.send(1)
    tx.send(2)
    tx.send(3)
    0

async fn consumer(rx: Receiver[i32]) -> i32:
    let a = rx.recv()
    let b = rx.recv()
    let c = rx.recv()
    a + b + c

async fn main:
    let pair = chan[i32](2)
    let tx = pair.0
    let rx = pair.1
    let p = producer(tx)
    let c = consumer(rx)
    let sum = c.await
    let _ = p.await
    assert(sum == 6)
    print("ok")
