//! expect-check-fail: an ephemeral value cannot be stored on the heap

// §5.1 (#600, #625): an ephemeral value cannot move into a heap-owning
// constructor. A tuple literal holding one is an ephemeral value too:
// `Box.new((view, 2))` put the view on the heap past its origin exactly as
// `Box.new(view)` would, and was accepted.
use std.box

type Keep = ephemeral { r: &i32 }

fn main:
    let local = 5
    let b = Box.new((Keep { r: &local }, 2))
    print("boxed")
