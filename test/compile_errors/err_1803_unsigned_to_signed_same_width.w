//! expect-error: implicit integer narrowing or sign change from `u32` to `i32`

// §4.2.6: unsigned converts to signed implicitly only when the destination is
// strictly wider (u32 -> i64); at the same width it needs `as`.
fn take(x: i32): print(f"{x}")

fn main:
    let u: u32 = 4000000000
    take(u)
