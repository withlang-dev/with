//! expect-build-fail: active defer/errdefer cleanup remains

@[tailrec]
fn f(n: i32) -> i32:
    if n <= 0: 0
    defer:
        let _ = int_to_string(n)
    f(n - 1)

fn main:
    let _ = f(3)
