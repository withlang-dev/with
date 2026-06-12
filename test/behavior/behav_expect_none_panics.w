//! expect-exit: 134
//! expect-stderr: user must exist in test setup
//! expect-stderr: None
//! expect-stderr: behav_expect_none_panics.w

fn main:
    let x: Option[i32] = None
    let _ = x.expect("user must exist in test setup")
