//! skip-windows: issue #797: panic exits 1 not 134 on native Windows
//! expect-exit: 134
//! expect-stderr: slice index out of bounds

fn main:
    let arr = [1, 2, 3]
    let _ = arr[0..4]
