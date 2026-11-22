//! expect-error: type mismatch in binding
// D44: a typed binding does not collect. `m.keys()` is a view iterator; an
// owned List is `m.keys() |> collect[List]()` (D111: the Copy views are
// copied into it).
use std.collections

fn main:
    var m: HashMap[i32, i32] = HashMap.new()
    m.insert(1, 2)
    let ks: List[i32] = m.keys()
    print(ks.len())
