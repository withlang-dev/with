//! expect-stdout: ok
// send/recv through a borrowed endpoint parameter (`&Sender[T]`, `&Receiver[T]`)
// in sync and async functions. The MIR classifies channel endpoint methods as
// intrinsics (#1293); before that a borrowed endpoint hit the generic-call
// contract BUG ("user generic call lacks a concrete contract").

use std.channel

fn give(tx: &Sender[i32], v: i32): tx.send(v)

fn take(rx: &Receiver[i32]) -> i32: rx.recv().unwrap()

async fn give_async(tx: &Sender[i32], v: i32) -> i32:
    tx.send(v)
    v

async fn take_async(rx: &Receiver[i32]) -> i32: rx.recv().unwrap()

async fn main:
    let (tx, rx) = chan[i32](4)
    give(&tx, 1)
    assert(take(&rx) == 1)
    assert(give_async(&tx, 2).await == 2)
    assert(take_async(&rx).await == 2)
    give(&tx, 3)
    tx.close()
    var total = 0
    for m in rx: total = total + m
    assert(total == 3)
    print("ok")
