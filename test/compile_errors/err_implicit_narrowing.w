//! expect-error: narrowing or sign

fn main:
    let big: i64 = 42
    let small: i32 = big
    print_i32(small)
