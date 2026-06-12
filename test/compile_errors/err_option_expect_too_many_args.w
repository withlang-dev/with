//! expect-check-fail: Option.expect() expects exactly one argument

fn main:
    let x: Option[i32] = Some(1)
    let _ = x.expect("one", "two")
