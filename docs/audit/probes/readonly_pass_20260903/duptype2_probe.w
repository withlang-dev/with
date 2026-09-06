use std.builtins.print_i32
type Dup { v: i32 }
type Dup { w: i32 }
fn main:
    let d = Dup { v: 1 }
    print_i32(d.v)
