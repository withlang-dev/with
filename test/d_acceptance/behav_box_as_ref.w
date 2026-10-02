//! expect-stdout: 42
// §3.7/§8 (#627): explicit Box.as_ref() on a primitive box returns a valid &T.
// Previously segfaulted — the transparent-box receiver was passed one
// indirection too shallow to the generic `&self` method.
use std.box.Box
use std.builtins.print_i32
fn main:
    let b = Box.new(42)
    print_i32(*b.as_ref())
