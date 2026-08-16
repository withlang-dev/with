//! skip-windows: issue #797: panic exits 1 not 134 on native Windows
//! expect-exit: 134
//! expect-stderr: integer overflow

fn main:
    let x: i32 = 2147483647
    let y = x + 1
    assert(y == 0)
