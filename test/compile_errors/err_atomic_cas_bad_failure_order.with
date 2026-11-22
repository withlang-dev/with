//! expect-error: compare_exchange failure ordering cannot be Release or AcqRel

use std.sync

var cell: Atomic[i32]

fn main:
    let _ = cell.compare_exchange(0, 1, .SeqCst, .Release)
