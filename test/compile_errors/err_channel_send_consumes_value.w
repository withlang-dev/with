//! expect-check-fail: use of moved value

fn main:
    let (tx, _rx) = chan[List[i32]](1)
    let values: List[i32] = List.new()
    tx.send(values)
    let _n = values.len()
