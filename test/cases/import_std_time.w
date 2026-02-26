// Test: std.time import
use std.time

fn main -> i32:
    let t = now()
    // Time should be a large positive number (seconds since 1970)
    assert(t > 1000000000)
