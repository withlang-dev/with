//! expect-check-fail: unsafe function call requires unsafe context
// #975: std.mem's raw helpers write through any pointer, so calling one is
// an unsafe operation. mem_set was a safe fn, and this zeroed a stack local
// from safe code.
use std.mem

fn main:
    var x: i64 = 42
    mem_set(&x as *i8, 0, 8)
    print(x)
