//! expect-error: implicit integer narrowing or sign change from `i64` to `i32`

// §4.2.6 (#1803): implicit narrowing is refused at every owned demand,
// as at an annotated `let`. This position accepted it and truncated.
let S0: i64 = 5
type S { a: i32 = S0 }

fn main:
    let r = S { }
    print(f"{r.a}")
