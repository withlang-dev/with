//! expect-error: E0702

use std.channel

fn main:
    let (tx, rx) = chan[i32](1)
    no_suspend:
        tx.send(1)
        let _ = rx.recv()
