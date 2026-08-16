//! skip-windows: issue #797: panic exits 1 not 134 on native Windows
//! expect-exit: 134
//! expect-stderr: index out of bounds

fn main:
    var arr = [1, 2, 3]
    arr[3] = 4
