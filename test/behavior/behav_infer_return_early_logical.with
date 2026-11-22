//! expect-stdout: ok

// #659 family: early `return <logical and/or>` must infer bool.
fn between(v: i32):
    if v >= 0:
        return v > 1 and v < 5
    false

fn main:
    assert(between(3))
    assert(not between(0))
    assert(not between(-1))
    print("ok")
