//! expect-error: wrong argument type in call to 'Vec.get'

fn main:
    let items: Vec[i32] = Vec.new()
    let borrowed = &items
    borrowed.get("x")
