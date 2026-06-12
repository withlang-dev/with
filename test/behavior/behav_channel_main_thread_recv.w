//! expect-stdout: ok

use std.channel

async fn producer(tx: Sender[i32]) -> i32:
    tx.send(42)
    0

fn main:
    let (tx, rx) = chan[i32](1)
    producer(tx)
    let value = rx.recv()
    assert(value == 42)
    print("ok")
