use std.channel
use std.builtins.print_i32
async fn producer(tx: Sender[i32]) -> i32:
    var i = 0
    while i < 20000:
        tx.send(i)
        i = i + 1
    0
async fn consumer(rx: Receiver[i32]) -> i64:
    var sum: i64 = 0
    var n = 0
    while n < 20000:
        match rx.recv():
            Some(v) => { sum = sum + v as i64; n = n + 1 }
            None => { n = 20000 }
    sum
async fn main:
    let (tx, rx) = chan[i32](0)
    async scope s =>:
        s.track(producer(move tx))
        let total = s.track(consumer(move rx))
        print_i32(total.await as i32)
