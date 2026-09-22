//! expect-stdout: ok
// #1293 (send side): a select loser parked in send() on a full bounded
// channel is cancelled at that suspension point; the unsent value is
// destroyed, nothing entered the channel, and the channel stays usable.

use std.channel

var loser_unwound: i32 = 0
var loser_continued: i32 = 0

async fn stuck(tx: &Sender[i32]) -> i32:
    defer: unsafe { loser_unwound = loser_unwound + 1 }
    tx.send(99)
    unsafe { loser_continued = loser_continued + 1 }
    0

async fn now -> i32: 1

async fn race(tx: &Sender[i32]) -> i32:
    let a = stuck(tx)
    let b = now()
    var fired = 0
    select await:
        _ = a => fired = 1
        x = b => fired = x + 1
    unsafe { assert(loser_unwound == 1) }
    unsafe { assert(loser_continued == 0) }
    fired

async fn main:
    let (tx, rx) = chan[i32](1)
    tx.send(5)                       // full: the loser's send must park
    assert(race(&tx).await == 2)
    assert(rx.recv().unwrap() == 5)  // only the pre-filled value is there
    tx.send(6)
    assert(rx.recv().unwrap() == 6)
    print("ok")
