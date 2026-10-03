//! expect-stdout: ok

fn main:
    let empty: HashMap[i32, str] = HashMap.new()
    let empty_keys = empty.keys()
    assert(empty_keys.len() == 0)

    var m: HashMap[i32, str] = HashMap.new()
    m.insert(1, "a")
    m.insert(2, "b")
    m.insert(1, "updated")

    let ks = m.keys()
    assert(ks.len() == 2)
    assert(ks.contains(1))
    assert(ks.contains(2))
    print("ok")
