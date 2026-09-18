use std.builtins.print_i32
fn rec[T](x: T) -> T: rec(x)
fn main:
    print_i32(rec(1))
