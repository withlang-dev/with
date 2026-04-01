//! expect-error: wrong argument type in call to 'HashSet.contains'

fn main:
    let set: HashSet[i32] = HashSet.new()
    let borrowed = &set
    borrowed.contains("x")
