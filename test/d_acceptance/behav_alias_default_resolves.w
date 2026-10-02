//! expect-stdout: 15
// §4.1 (#627): unshadowed, the friendly aliases still resolve (Int=i64,
// UInt=u64, String=str).
use std.builtins.print_i32
fn main:
    let a: Int = 5
    let b: UInt = 10
    let _s: String = "ok"
    print_i32(a as i32 + b as i32)
