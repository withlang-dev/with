//! skip-windows: issue #797: panic exits 1 not 134 on native Windows
//! expect-exit: 134
//! expect-stderr: integer overflow

fn main:
    let x: u8 = 255
    let y = x + 1u8
    assert(y == 0)
