//! expect-stdout: 99
// §8 (#627): Rc.as_ref() — transparent refcounted box, same receiver fix.
use std.rc.Rc
use std.builtins.print_i32
fn main:
    let r = Rc.new(99)
    print_i32(*r.as_ref())
