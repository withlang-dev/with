//! expect-exit: 134
//! expect-stderr: integer does not fit `i32`
// §4.2.6 (D183): a value the destination cannot hold panics, as an
// out-of-range index does (D71); `as` would have wrapped it.
fn main:
    let big: i64 = 5000000000
    let small: i32 = big
    print(small)
