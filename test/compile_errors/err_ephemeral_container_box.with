//! expect-check-fail: cannot be stored on the heap
// §5.1 (#625): boxing an ephemeral value (here via a struct literal) is a heap
// escape — the #600 heap-boxing gate fires.
use std.box.Box
type View ephemeral { p: &i32 }

fn main:
    let x = 5
    let b: Box[View] = Box.new(View { p: &x })
    let _ = b
