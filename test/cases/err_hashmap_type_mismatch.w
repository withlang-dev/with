//! expect-error: argument 2 expects i32
fn main:
    let m: HashMap[str, i32] = HashMap.new()
    m.insert("key", "not_an_int")
