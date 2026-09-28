//! expect-error: a Result for-comprehension clause binds with a refutable pattern

// §13.6a: an `Ok` the clause's pattern does not match has no Err value to
// fail with (the same reason Result comprehensions take no guard).
fn pair() -> Result[(i32, i32), str]: Ok((1, 2))

fn main:
    let r = for (a, 1) in pair(): yield a
    print(f"{r:?}")
