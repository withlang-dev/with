//! expect-exit: 134
//! expect-stderr: deadlock: send on a full channel, and no task is left that could receive from it
// #1000: outside a fiber, a send to a full bounded channel that no task can
// drain waits forever (channels.md: send suspends while full). The runtime
// returned instead and the value vanished; it is a deadlock, said aloud.
use std.channel

fn main:
    let (tx, rx) = chan[i32](1)
    tx.send(10)
    tx.send(20)
    print(rx.recv() ?? -1)
