//! expect-error: method 'HashMap.insert' requires a mutable receiver

fn main:
    let lookup: HashMap[str, i32] = HashMap.new()
    let shared = &lookup
    shared.insert("a", 1)
