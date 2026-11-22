//! expect-error: an `extern "C" fn` type cannot take an array by value

// #1975 (C11 6.7.6.3p7): C adjusts an array parameter to a pointer, so no
// C function type takes an array by value.
fn main:
    let f: Option[extern "C" fn([u8; 4]) -> i32] = None
    print(f.is_none())
