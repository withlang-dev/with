// Test: std.process import
use std.process

fn main() -> i32 =
    let p = pid()
    // PID should be positive
    assert(p > 0)
    0
