use std.sync
use std.channel
async fn work() -> i32:
  42
async fn main:
  let lock = Mutex[i64].new(1 as i64)
  let (tx, rx) = chan[i32](1)
  let task = work()
  with lock.enter() as data:
    assert(*data == 1)
    tx.send(1)
