//! expect-check-fail: closure return type mismatch

fn main:
    let f: fn() -> i32 = () => "bad"
    let _ = f()
