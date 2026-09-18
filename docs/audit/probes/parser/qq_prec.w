use std.builtins.print_i32
fn main:
    let x: Option[i32] = None
    let v = x ?? 2 + 3
    print_i32(v)
