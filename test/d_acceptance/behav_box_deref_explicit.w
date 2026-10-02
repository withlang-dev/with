//! expect-stdout: 42
// §3.7 (#627): explicit .deref() (Deref impl) on a box matches auto-deref.
use std.box.Box
use std.builtins.print_i32
fn main:
    let b = Box.new(42)
    print_i32(*b.deref())
