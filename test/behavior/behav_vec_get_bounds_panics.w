//! expect-exit: 1
//! expect-stderr: Vec index out of bounds

fn main:
    let values: Vec[i32] = Vec.new()
    values.push(1)
    let _ = values[1]
