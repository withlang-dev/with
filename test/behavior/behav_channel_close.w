//! expect-stdout: ok

use std.channel

fn make_sender(ch: Channel[i32]) -> Sender[i32]:
    Sender { handle: ch.handle }

fn make_receiver(ch: Channel[i32]) -> Receiver[i32]:
    Receiver { handle: ch.handle }

async fn producer(tx: Sender[i32]) -> i32:
    tx.send(1)
    tx.send(2)
    tx.close()
    0

async fn consumer(rx: Receiver[i32]) -> i32:
    let a = rx.recv()
    let b = rx.recv()
    a + b

async fn main:
    let ch = Channel[i32].new(8)
    let tx = make_sender(ch)
    let rx = make_receiver(ch)
    let p = producer(tx)
    let c = consumer(rx)
    let sum = c.await
    let _ = p.await
    assert(sum == 3)
    print("ok")
