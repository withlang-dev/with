//! expect-stdout: ok

use std.channel

async fn producer(ch: Sender[i32]) -> i32:
    ch.send(42)
    ch.send(100)
    0

async fn consumer(ch: Receiver[i32]) -> i32:
    let a = ch.recv().unwrap()
    let b = ch.recv().unwrap()
    a + b

async fn main:
    let (tx, rx) = chan[i32](8)
    let p = producer(move tx)
    let c = consumer(move rx)
    let result = c.await
    let _ = p.await
    assert(result == 142)
    print("ok")
