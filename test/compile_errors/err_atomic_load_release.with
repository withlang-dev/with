//! expect-error: load cannot use Release or AcqRel ordering

use std.sync

var cell: Atomic[i32]

fn main:
    let _ = cell.load(.Release)
