//! expect-error: Atomic[T] requires integer or pointer T

use std.sync

var bad: Atomic[Vec[i32]]

fn main:
    ()
