//! expect-check-fail: use of moved value

type Tok { id: i32 }
impl Drop for Tok:
    move fn drop(): {}
fn main:
    let (tx, _rx) = chan[List[Tok]](1)
    let values: List[Tok] = List.new()
    tx.send(values)
    let _n = values.len()
