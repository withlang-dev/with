//! expect-stdout: ok

// §14.15 (D55): dropping the original sender while a clone lives keeps the
// channel open. Sends through the surviving clones land; the channel closes
// only when the last one drops. Runs on the main thread so every step is
// deterministic: recv never blocks here because each read has a queued
// value or sees the closed channel.

use std.channel

fn main:
    let (tx, rx) = chan[i32](8)
    let a = tx.clone()
    let b = a.clone()
    drop(tx)
    a.send(1)
    drop(a)
    b.send(2)
    assert(rx.recv().unwrap() == 1)
    drop(b)
    assert(rx.recv().unwrap() == 2)
    assert(rx.recv().is_none())
    print("ok")
