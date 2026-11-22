//! expect-error: return type mismatch

// #1368: an aggregate's elements do not convert on return either; this was
// invalid MIR ("use rvalue type is incompatible with assign destination").
fn pair -> (i32, i32): (3, 4)
fn wide -> (i64, i64): pair()
fn main:
    let w = wide()
    print(f"{w.0}")
