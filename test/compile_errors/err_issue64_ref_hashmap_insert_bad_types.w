//! expect-error: wrong argument type in call to 'HashMap.insert'

fn main:
    var lookup: HashMap[str, i32] = HashMap.new()
    let borrowed = &mut lookup
    borrowed.insert(1, "x")
