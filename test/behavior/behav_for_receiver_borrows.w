//! expect-stdout: first 1
//! expect-stdout: first 2
//! expect-stdout: then 3
//! expect-stdout: then 4
//! expect-stdout: done

// §13, D10: `for msg in rx` borrows the receiver, as `for x in list` borrows
// the list: a loop left by `break` leaves `rx` open and the program's. The
// loop moved `rx` into a temporary that it dropped at the loop's end,
// closing the receiver and blanking `rx`, so the receives after it read a
// blank and saw nothing.
use std.channel

async fn main:
    let (tx, rx) = chan[i32](8)
    for i in 1..5:
        tx.send(i)
    drop(tx)
    for msg in rx:
        print(f"first {msg}")
        if msg == 2:
            break
    while true:
        match rx.recv():
            Some(m) => print(f"then {m}")
            None => break
    print("done")
