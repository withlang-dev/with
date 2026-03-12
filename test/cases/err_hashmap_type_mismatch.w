//! expect-error: wrong argument type
fn main:
    let m: HashMap[str, i32] = HashMap.new()
    m.insert("key", "not_an_int")
