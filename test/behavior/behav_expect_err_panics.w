//! skip-windows: issue #797: panic exits 1 not 134 on native Windows
//! expect-exit: 134
//! expect-stderr: operation failed
//! expect-stderr: "bad"
//! expect-stderr: behav_expect_err_panics.w

fn main:
    let r: Result[i32, str] = Err("bad")
    let _ = r.expect("operation failed")
