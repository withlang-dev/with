//! expect-stdout: ok

fn main:
    var direct: HashMap[str, i32] = HashMap.new()
    direct.insert("a", 7)
    direct.insert("b", 8)
    let removed = direct.remove("a")
    assert(removed.unwrap() == 7)
    assert(direct.len() == 1)
    assert(direct.remove("missing").is_none())

    var borrowed: HashMap[str, i32] = HashMap.new()
    borrowed.insert("x", 9)
    borrowed.insert("y", 10)
    assert(borrowed.remove("x").unwrap() == 9)
    assert(borrowed.len() == 1)
    assert(borrowed.remove("x").is_none())

    print("ok")
