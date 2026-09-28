//! expect-error: implicit integer narrowing or sign change from `i32` to `u32`

// §4.2.6 (#1803): no implicit numeric conversion but a lossless widening.
// `take(s)` with `s: i32 = -1` into `u32` passed 4294967295.
fn take(x: u32): print(f"{x}")

fn main:
    let s: i32 = -1
    take(s)
