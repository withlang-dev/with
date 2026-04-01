//! expect-error: recursive call is not in tail position

@[tailrec]
fn bad(n: i32) -> i32:
    if n <= 0: 0
    else: 1 + bad(n - 1)

fn main:
    bad(5)
