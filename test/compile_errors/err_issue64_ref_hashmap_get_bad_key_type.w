//! expect-error: wrong argument type in call to 'HashMap.get'

fn main:
    let lookup: HashMap[str, i32] = HashMap.new()
    let borrowed = &lookup
    borrowed.get(1)
