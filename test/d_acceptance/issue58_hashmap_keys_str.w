//! expect-stdout: ok

fn main:
    var m: HashMap[str, i32] = HashMap.new()
    m.insert("alpha", 1)
    m.insert("beta", 2)
    m.insert("alpha", 3)

    let ks = m.keys()
    assert(ks.len() == 2)
    assert(ks.contains("alpha"))
    assert(ks.contains("beta"))
    print("ok")
