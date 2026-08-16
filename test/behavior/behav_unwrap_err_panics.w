//! expect-exit: 134
//! expect-stderr: called unwrap on Err
//! expect-stderr: "boom"
//! expect-stderr: behav_unwrap_err_panics.w

fn main:
    let r: Result[i32, str] = Err("boom")
    let _ = r.unwrap()
