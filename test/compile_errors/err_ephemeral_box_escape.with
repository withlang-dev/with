//! expect-check-fail: cannot be stored on the heap

// #600 (§5.1): an ephemeral value (borrow-holding struct) cannot be moved by
// value into Box.new — the heap copy would outlive the borrowed storage.

use std.box.Box
type StrView ephemeral { s: &str }

fn main:
    let owned = "hello"
    let view = StrView { s: owned }
    let boxed = Box.new(view)
    print("no")
