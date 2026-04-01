//! expect-error: wrong argument type in call to 'HashMap.get'

fn main:
    let lookup: HashMap[str, i32] = HashMap.new()
    lookup.get(1)
