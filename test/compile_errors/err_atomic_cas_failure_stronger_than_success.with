//! expect-error: compare_exchange failure ordering cannot be stronger than success ordering

use std.sync

var cell: Atomic[i32]

fn main:
    let _ = cell.compare_exchange(0, 1, .Relaxed, .Acquire)
