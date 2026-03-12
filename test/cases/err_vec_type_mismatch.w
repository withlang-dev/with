//! expect-error: wrong argument type
fn main:
    let v: Vec[i32] = Vec.new()
    v.push("hello")
