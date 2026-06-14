//! expect-check-fail: shadowing is not allowed for 'x'

fn main:
    let x = 1
    let x = x + 1
    print(f"{x}")
