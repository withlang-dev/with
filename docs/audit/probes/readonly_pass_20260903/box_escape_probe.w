use std.box
use std.builtins.print_i32
type Holder = ephemeral { r: &i32 }
fn main:
    let x = 42
    let h = Holder { r: &x }
    let b = Box.new(h)
    print_i32(*b.r)
