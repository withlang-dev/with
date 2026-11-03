//! expect-stdout: got 7
//! expect-stdout: ok
// §14.10: a channel receive as a select await arm, spelled as the spec's
// first example (`msg = rx.recv() => ...`). The other arm is a task parked
// on a channel nothing sends to; cancelled, it unwinds, and the channel it
// watched is untouched. #2956
use std.channel
var loser_unwound: i32 = 0
async fn never(rx: &Receiver[i64]) -> i64:
    defer: unsafe { loser_unwound = loser_unwound + 1 }
    rx.recv().unwrap()
async fn main:
    let (tx, rx) = chan[i64](4)
    let (tx_quiet, rx_quiet) = chan[i64](1)
    let parked = never(&rx_quiet)
    tx.send(7)
    select await:
        v = rx.recv() => print(f"got {v.unwrap()}")
        _ = parked => print("parked first")
    unsafe { assert(loser_unwound == 1) }
    tx_quiet.send(1)
    assert(rx_quiet.recv().unwrap() == 1)
    print("ok")
