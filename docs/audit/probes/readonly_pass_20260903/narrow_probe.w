use std.mem
use std.builtins.print_i32
fn take32(n: i32) -> i32: n
fn main:
    let big: i64 = 100000
    let a = take32(big)
    let p = alloc(16)
    mem_set(p, 0, big)
    print_i32(a)
