//! expect-error: store cannot use Acquire or AcqRel ordering

use std.sync

var cell: Atomic[i32]

fn main:
    cell.store(1, .Acquire)
