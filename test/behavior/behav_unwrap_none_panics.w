//! expect-exit: 134
//! expect-stderr: called unwrap on None
//! expect-stderr: behav_unwrap_none_panics.w

fn main:
    let x: Option[i32] = None
    let _ = x.unwrap()
