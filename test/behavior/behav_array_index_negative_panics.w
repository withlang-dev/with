//! skip-windows: issue #797: panic exits 1 not 134 on native Windows
//! expect-exit: 134
//! expect-stderr: index out of bounds

fn main:
    let arr = [1, 2, 3]
    let i = -1
    let _ = arr[i]
