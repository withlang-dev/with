// Test: std.thread import
use std.thread

fn worker -> i32:
    42

fn main -> i32:
    let h = spawn_os(worker)
    let v = join(h)
    assert(v == 42)
