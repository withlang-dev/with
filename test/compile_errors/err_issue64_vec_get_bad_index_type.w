//! expect-error: Vec has no 'get': element access is spelled 'xs[i]'

fn main:
    let items: Vec[i32] = Vec.new()
    items.get("x")
