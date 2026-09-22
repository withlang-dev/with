//! expect-stdout: ok
// #1293: a select loser parked in recv() on an empty channel is cancelled at
// that suspension point (§14.7, §14.10): its destructors run, the select
// fires the ready branch, and the channel is untouched afterwards.

use std.channel

var loser_unwound: i32 = 0
var loser_continued: i32 = 0

async fn never(rx: &Receiver[i32]) -> i32:
    defer: unsafe { loser_unwound = loser_unwound + 1 }
    let got = rx.recv().unwrap()
    unsafe { loser_continued = loser_continued + 1 }
    got

async fn now -> i32: 1

async fn race(rx: &Receiver[i32]) -> i32:
    let a = never(rx)
    let b = now()
    var fired = 0
    select await:
        _ = a => fired = 1
        x = b => fired = x + 1
    unsafe { assert(loser_unwound == 1) }
    unsafe { assert(loser_continued == 0) }
    fired

async fn main:
    let (tx, rx) = chan[i32](4)
    assert(race(&rx).await == 2)
    // The cancelled recv consumed nothing and left the channel usable.
    tx.send(7)
    tx.send(8)
    assert(rx.recv().unwrap() == 7)
    assert(rx.recv().unwrap() == 8)
    print("ok")
