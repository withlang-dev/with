//! expect-error: implicit integer narrowing or sign change from `i64` to `i32`

// §4.2.6 (#1803): implicit narrowing is refused at every owned demand,
// as at an annotated `let`. This position accepted it and truncated.
type S { a: i32 }

fn main:
    let s: i64 = 5
    let r = S { a: s }
    print(f"{r.a}")
