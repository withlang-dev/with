//! expect-error: implicit integer narrowing or sign change from `i64` to `i32`

// §4.2.6 (#1803): implicit narrowing is refused at every owned demand,
// as at an annotated `let`. This position accepted it and truncated.
fn main:
    let s: i64 = 5
    let p: (i32, i32) = (0, s)
    print(f"{p.1}")
