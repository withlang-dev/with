//! expect-error: actual type: Vec[str]
fn takes_vec_i32(v: Vec[i32]) -> i32:
    0

fn main:
    let v: Vec[str] = Vec.new()
    takes_vec_i32(v)
