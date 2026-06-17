//! expect-check-fail: use of moved value

fn main:
    let (tx, _rx) = chan[Vec[i32]](1)
    let values: Vec[i32] = Vec.new()
    tx.send(values)
    let _n = values.len()
