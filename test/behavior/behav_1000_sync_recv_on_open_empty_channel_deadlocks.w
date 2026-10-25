//! expect-exit: 134
//! expect-stdout: 10
//! expect-stderr: deadlock: recv on an empty, open channel, and no task is left that could send to it
// #1000: None means closed and drained (channels.md). An empty channel that
// is still open, with no task left to send, was None too: the caller could
// not tell it from a closed one. It is a deadlock, said aloud.
use std.channel

fn main:
    let (tx, rx) = chan[i32](1)
    tx.send(10)
    print(rx.recv() ?? -1)
    print(rx.recv() ?? -1)
    tx.close()
