//! expect-stdout: ok

use std.collections.HashMap
fn main:
    var m: HashMap[str, i32] = HashMap.new()
    m.insert("alpha", 1)
    m.insert("beta", 2)
    m.insert("alpha", 3)

    let ks = m.keys() |> map(it.clone()) |> collect[Vec]()
    assert(ks.len() == 2)
    assert(ks[0] == "alpha")
    assert(ks[1] == "beta")
    print("ok")
