use std.builtins.print_i32
fn main:
    let x: Option[i32] = Some(10)
    let v = x ?? 2 + 3
    print_i32(v)
