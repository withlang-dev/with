//! expect-error: narrowing or sign

fn main:
    let x: i32 = 42
    let y: u32 = x
    print_i32(y as i32)
