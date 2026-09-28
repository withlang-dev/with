//! expect-error: implicit integer narrowing or sign change from `i64` to `i32`

// §4.2.6 (#1803): under an owned demand each arm of an `if` or `match` is the
// demand's value. `take(if c: 5 else: big)` passed 705032704 for 5000000000.
fn take(x: i32): print(f"{x}")

fn main:
    let big: i64 = 5000000000
    let c = false
    take(if c: 5 else: big)
