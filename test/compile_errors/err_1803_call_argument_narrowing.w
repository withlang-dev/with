//! expect-error: implicit integer narrowing or sign change from `i64` to `i32`

// §4.2.6 (#1803): implicit narrowing is refused at every owned demand,
// as at an annotated `let`. This position accepted it and truncated.
fn take(x: i32): print(f"{x}")

fn main:
    let s: i64 = 5
    take(s)
