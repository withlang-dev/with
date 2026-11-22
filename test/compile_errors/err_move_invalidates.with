//! expect-check-fail: use of moved value
fn callee(x: i32) -> i32:
    return x

fn main:
    let a: i32 = 5
    let _ = callee(move a)
    let _ = callee(a)   // error: a was moved
