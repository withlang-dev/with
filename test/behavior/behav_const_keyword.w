//! expect-stdout: ok

const MAX: i32 = 100

fn main:
    assert(MAX == 100)
    const LOCAL: i32 = 42
    assert(LOCAL == 42)
    print("ok")
