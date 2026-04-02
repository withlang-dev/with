//! expect-stdout: ok

use std.channel

async fn producer(ch: Sender[i32]) -> i32:
    ch.send(42)
    ch.send(100)
    0

async fn consumer(ch: Receiver[i32]) -> i32:
    let a = ch.recv()
    let b = ch.recv()
    a + b

async fn main:
    let pair = chan[i32](8)
    let tx = pair.0
    let rx = pair.1
    let p = producer(tx)
    let c = consumer(rx)
    let result = c.await
    let _ = p.await
    assert(result == 142)
    print("ok")
