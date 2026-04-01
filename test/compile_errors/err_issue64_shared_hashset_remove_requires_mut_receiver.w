//! expect-error: method 'HashSet.remove' requires a mutable receiver

fn main:
    let values: HashSet[i32] = HashSet.new()
    let shared = &values
    shared.remove(1)
