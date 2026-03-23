//! expect-error: in call to 'Vec.push'
fn main:
    let v: Vec[i32] = Vec.new()
    v.push("hello")
