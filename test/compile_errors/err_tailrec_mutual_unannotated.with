//! expect-build-fail: every function in the cycle must be annotated @[tailrec]

@[tailrec]
fn even(n: i32) -> bool:
    if n == 0: true
    else: odd(n - 1)

fn odd(n: i32) -> bool:
    if n == 0: false
    else: even(n - 1)

fn main:
    let _ = even(3)
