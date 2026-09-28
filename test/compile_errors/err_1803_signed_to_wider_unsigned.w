//! expect-error: implicit integer narrowing or sign change from `i32` to `u64`

// §4.2.6: "Signed-to-unsigned and unsigned-to-signed conversions also require
// `as`" — at any width. An i32 widened into u64 implicitly, -1 became
// 18446744073709551615.
fn main:
    let s: i32 = -1
    let u: u64 = s
    print(f"{u}")
