//! expect-check-fail: @[effect] names unknown parameter 'q'

@[effect(q: read)]
fn f(p: i32) -> i32:
    p

fn main:
    let _ = f(1)
