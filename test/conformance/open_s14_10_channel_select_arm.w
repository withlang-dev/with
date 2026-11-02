//! expect-stdout: got 7
// §14.10: a channel receive as a select await arm. #2956
use std.channel
async fn producer(tx: Sender[i64]) -> i64:
    tx.send(7)
    tx.close()
    0
async fn main:
    let (tx, rx) = chan[i64](4)
    let p = producer(tx)
    select await:
        v = rx.recv() => print(f"got {v}")
        _ = p => print("producer first")
    p.await
