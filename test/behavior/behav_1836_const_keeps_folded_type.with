//! expect-stdout: 4294967295 7 255 5

// #1836: an unannotated const whose value folds at compile time keeps the
// value's type. The fold left a bare literal, which the defaults typed i64
// (4294967295) or i32 (7) when the program was checked again.
const MAX_U32 = (0 as u32) -% 1
const SEVEN = (7 as u16)
const BYTE = 0xFFu8
const FIVE = 5

fn main:
    let a: u32 = MAX_U32
    let b: u16 = SEVEN
    let c: u8 = BYTE
    let d: i32 = FIVE
    print(f"{a} {b} {c} {d}")
