//! expect-stdout: ok

// #653 family: early `return <arithmetic>` must infer the operand type.
fn bump(v: i32):
    if v > 0:
        return v + 1
    0

fn main:
    assert(bump(3) == 4)
    assert(bump(0) == 0)
    assert(bump(-1) == 0)
    print("ok")
