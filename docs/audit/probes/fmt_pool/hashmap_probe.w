use std.collections.HashMap
fn main:
    let m: HashMap[str, i32] = HashMap.new()
    m.insert("alpha", 1)
    m.insert("beta", 2)
    m.insert("alpha", 3)
    print(m.get("alpha").unwrap().to_string())
    print(m.get("beta").unwrap().to_string())
    print(m.len().to_string())
