//! expect-check-fail: non-associative operator cannot be chained

fn main:
    let x = 1
    let _ = x == x == true
