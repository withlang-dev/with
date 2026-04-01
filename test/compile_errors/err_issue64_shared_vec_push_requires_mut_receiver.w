//! expect-error: method 'Vec.push' requires a mutable receiver

fn main:
    let items: Vec[i32] = Vec.new()
    let shared = &items
    shared.push(1)
