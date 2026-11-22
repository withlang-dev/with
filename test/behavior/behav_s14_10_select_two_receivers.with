//! expect-stdout: fast: 1
//! expect-stdout: slow: 2
// §14.10: two channel receives race as select await arms; the loser,
// parked in recv(), is cancelled and the channel it watched is untouched,
// so a second select reads it. #2956
use std.channel
async fn main:
    let (tx_fast, rx_fast) = chan[i64](1)
    let (tx_slow, rx_slow) = chan[i64](1)
    tx_fast.send(1)
    select await:
        msg = rx_fast.recv() => print(f"fast: {msg.unwrap()}")
        msg = rx_slow.recv() => print(f"slow: {msg.unwrap()}")
    tx_slow.send(2)
    select await:
        msg = rx_fast.recv() => print(f"fast: {msg.unwrap()}")
        msg = rx_slow.recv() => print(f"slow: {msg.unwrap()}")
