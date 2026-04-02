//! expect-stdout: ok

use std.channel

fn make_sender(handle: i64) -> Sender[i32]:
    Sender { handle }

fn make_receiver(handle: i64) -> Receiver[i32]:
    Receiver { handle }

async fn producer(tx: Sender[i32]) -> i32:
    // Send more items than channel capacity to test bounded backpressure
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
    let handle = with_channel_create(2, 4)
    let tx = make_sender(handle)
    let rx = make_receiver(handle)
    let p = producer(tx)
    let c = consumer(rx)
    let sum = c.await
    let _ = p.await
    assert(sum == 6)
    print("ok")
