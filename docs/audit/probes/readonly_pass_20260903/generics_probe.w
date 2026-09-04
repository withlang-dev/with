use std.builtins.print_i32
fn ident[T](x: T) -> T: x
fn main:
    print_i32(ident(10) + ident(20))
    print_i32(if ident("a") == "a": 1 else: 0)
