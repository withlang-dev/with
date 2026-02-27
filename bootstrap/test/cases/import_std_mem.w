// Test: std.mem and std.fmt imports
use std.mem
use std.fmt

fn main -> i32:
    // Test memory allocation
    let buf = alloc(256)
    assert(buf != 0)
    mem_set(buf, 0, 256)

    // Test formatting into buffer
    let n = fmt_int(buf, 256, 42)
    assert(n == 2)

    free_mem(buf)
    0
