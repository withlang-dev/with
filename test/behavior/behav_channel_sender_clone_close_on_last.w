//! expect-stdout: ok

// §14.15 (D55): Sender[T] is Clone, never Copy. Every clone holds the
// channel open; the receiver sees None only after the LAST sender drops.
// Three producers (the original and two clones) each send once and drop
// their sender at fiber exit; the consumer must count all three.

use std.channel

async fn producer(id: i32, tx: Sender[i32]) -> i32:
    tx.send(id)
    id

async fn consumer(rx: Receiver[i32]) -> i32:
    var sum = 0
    var count = 0
    for msg in rx:
        sum = sum + msg
        count = count + 1
    assert(rx.recv().is_none())
    assert(count == 3)
    sum

async fn main:
    let (tx, rx) = chan[i32](8)
    let p1 = producer(1, tx.clone())
    let p2 = producer(2, tx.clone())
    let p3 = producer(3, move tx)
    let c = consumer(move rx)
    let sum = c.await
    let _ = p1.await
    let _ = p2.await
    let _ = p3.await
    assert(sum == 6)
    print("ok")
