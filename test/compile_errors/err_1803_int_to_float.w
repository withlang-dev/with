//! expect-error: an integer where a float is demanded needs an explicit `as f64`

// §4.2.6 (#1803): no implicit numeric conversion but a lossless widening.
// An i32 stored into an f64 array element was its bit pattern (3.5e-323).
fn main:
    let s: i32 = 7
    let a: [2]f64 = [0.0, s]
    print(f"{a[1]}")
