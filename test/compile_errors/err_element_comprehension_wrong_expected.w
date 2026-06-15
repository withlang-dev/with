//! expect-error: type mismatch in binding

fn main:
    let _bad: i32 = [x for x in 0..3]
