//! expect-error: type mismatch in binding
// D44: a typed binding does not collect. `m.keys()` is a view iterator; an
// owned Vec is `m.keys() |> map(it.clone()) |> collect[Vec]()`.
use std.collections

fn main:
    var m: HashMap[i32, i32] = HashMap.new()
    m.insert(1, 2)
    let ks: Vec[i32] = m.keys()
    print(ks.len())
