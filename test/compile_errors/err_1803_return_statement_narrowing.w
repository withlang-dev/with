//! expect-error: implicit integer narrowing or sign change from `i64` to `i32`

// §4.2.6 (#1803): implicit narrowing is refused at every owned demand,
// as at an annotated `let`. This position accepted it and truncated.
fn f(s: i64) -> i32:
    return s

fn main:
    print(f"{f(5)}")
