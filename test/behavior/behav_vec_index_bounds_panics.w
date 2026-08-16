//! expect-exit: 134
//! expect-stderr: index out of bounds

fn main:
    let values: Vec[i32] = Vec.new()
    values.push(1)
    let _ = values[1]
