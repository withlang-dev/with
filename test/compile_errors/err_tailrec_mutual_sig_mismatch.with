//! expect-build-fail: differing function signatures or calling conventions

@[tailrec]
fn a(n: i32) -> i32:
    if n <= 0: 0
    else: b(n - 1, 1)

@[tailrec]
fn b(n: i32, acc: i32) -> i32:
    if n <= 0: acc
    else: a(n - 1)

fn main:
    let _ = a(3)
