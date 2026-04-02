//! expect-stdout: ok

use std.channel

fn make_sender(handle: i64) -> Sender[i32]:
    Sender { handle }

fn make_receiver(handle: i64) -> Receiver[i32]:
    Receiver { handle }

async fn producer(ch: Sender[i32]) -> i32:
    ch.send(42)
    ch.send(100)
    0

async fn consumer(ch: Receiver[i32]) -> i32:
    let a = ch.recv()
    let b = ch.recv()
    a + b

async fn main:
    let handle = with_channel_create(8, 4)
    let tx = make_sender(handle)
    let rx = make_receiver(handle)
    let p = producer(tx)
    let c = consumer(rx)
    let result = c.await
    let _ = p.await
    assert(result == 142)
    print("ok")
