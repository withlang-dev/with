//! expect-debug-alloc: leak count=0

// Spawns producer/consumer fibers with channel endpoints moved into each task
// and awaits both. Before the shutdown-ordering fix this leaked the two pooled
// fiber control blocks (origin=fiber, size=512) because the debug-alloc ledger
// was walked before with_runtime_core_shutdown freed the fiber pool. The
// channel handle/buffer were already freed via Sender/Receiver Drop, so this
// fixture pins fiber-lifecycle cleanup specifically: leak count must be 0.

use std.channel

async fn producer(tx: Sender[i32]) -> i32:
    tx.send(1)
    tx.send(2)
    tx.send(3)
    0

async fn consumer(rx: Receiver[i32]) -> i32:
    let a = rx.recv().unwrap()
    let b = rx.recv().unwrap()
    let c = rx.recv().unwrap()
    a + b + c

async fn main:
    let pair = chan[i32](2)
    let (tx, rx) = pair
    let p = producer(move tx)
    let c = consumer(move rx)
    let sum = c.await
    let _ = p.await
    assert(sum == 6)
    print("ok")
