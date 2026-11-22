//! expect-stdout: ok

// #653 matrix: early `return true` with an explicit `return false` tail.
fn g(v: i32):
    if v == 1:
        return true
    return false

fn main:
    assert(g(1))
    assert(not g(2))
    print("ok")
