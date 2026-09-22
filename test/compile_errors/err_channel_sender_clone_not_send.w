//! expect-error: channel element type must be Send

// §14.15 (D55): Sender[T] is Send only when T is Send, so a cloned sender
// cannot carry a non-Send payload across fibers. Rc[i32] is not Send: the
// channel is rejected at the element type, and the clone handed to the
// worker never exists.

use std.channel
use std.rc

async fn worker(tx: Sender[Rc[i32]]) -> i32:
    tx.send(Rc.new(1))
    0

async fn main:
    let (tx, rx) = chan[Rc[i32]](1)
    let t = worker(tx.clone())
    let _ = rx.recv()
    let _ = t.await
