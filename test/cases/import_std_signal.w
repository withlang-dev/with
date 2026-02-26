// Test: std.signal import
use std.signal

fn main -> i32:
    assert(sigint() > 0)
    assert(sigterm() > 0)
    assert(sigkill() > 0)
