//! expect-stdout: 7
// §3.7/§8 (#627): Box.as_ref() on a struct box, then field access.
use std.box.Box
use std.builtins.print_i32
type Owned { n: i32 }
fn main:
    let b = Box.new(Owned { n: 7 })
    print_i32(b.as_ref().n)
