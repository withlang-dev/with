//! expect-exit: 134
//! expect-stderr: integer overflow

// #914: checked arithmetic at exactly 2^127-1 — one past the top traps.
fn bump(v: i128) -> i128: v + 1

fn main:
    let max: i128 = 170141183460469231731687303715884105727
    print(bump(max))
