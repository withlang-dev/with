// T4 (blocking/yield) + T10 close-drain probe, async context.
// Producer sends 0..999 then returns; dropping tx closes the channel
// (rt/channel_runtime.w:242-250). Consumer drains until None.
// Expected: count == 1000, sum == 499500 (exact under 1 worker).
use std.channel
use std.builtins.print
use std.builtins.print_i64

async fn producer(tx: Sender[i32]) -> i32:
    var i = 0
    while i < 1000:
        tx.send(i)
        i = i + 1
    0

async fn consumer(rx: Receiver[i32]) -> i64:
    var sum: i64 = 0
    var n = 0
    var open = true
    while open:
        match rx.recv():
            Some(v) => { sum = sum + v as i64; n = n + 1 }
            None => { open = false }
    assert(n == 1000)
    sum

async fn main:
    let (tx, rx) = chan[i32](8)
    let p = producer(move tx)
    let c = consumer(move rx)
    let total = c.await
    let _ = p.await
    assert(total == 499500)
    print_i64(total)
    print("drain-ok")
