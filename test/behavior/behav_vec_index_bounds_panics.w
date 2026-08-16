//! skip-windows: issue #797: panic exits 1 not 134 on native Windows
//! expect-exit: 134
//! expect-stderr: index out of bounds

fn main:
    let values: Vec[i32] = Vec.new()
    values.push(1)
    let _ = values[1]
