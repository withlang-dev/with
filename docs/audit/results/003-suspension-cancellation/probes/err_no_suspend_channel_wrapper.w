use std.channel

fn receive(rx: Receiver[i32]) -> Option[i32]: rx.recv()

fn main:
    let (tx, rx) = chan[i32](1)
    tx.send(1)
    no_suspend:
        let _ = receive(move rx)
