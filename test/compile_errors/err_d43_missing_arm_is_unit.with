//! expect-check-fail: type mismatch in binding

// D43 / #1179: a missing else makes the function Unit. It once inferred i32
// and returned a fabricated 0 when the pattern did not match.

var seen: i32
fn subject(p: bool) -> Option[i32]:
    if p: Some(7) else: None
fn f(p: bool):
    if let Some(v) = subject(p): seen = v

fn main:
    let r: i32 = f(false)
