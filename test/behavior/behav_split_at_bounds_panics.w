//! skip-windows: issue #797: panic exits 1 not 134 on native Windows
//! expect-exit: 134
//! expect-stderr: split_at index out of bounds

fn main:
    let xs = [1, 2, 3]
    let _parts = xs.split_at(4)
