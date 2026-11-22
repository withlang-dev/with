//! expect-stdout: ok

// #653: an unannotated fn with an early `return <bool literal>` and a tail
// bool must infer bool, not silently finalize Unit.
fn f(v: i32):
    if v == 3:
        return true
    false

fn main:
    assert(f(3))
    assert(not f(4))
    print("ok")
