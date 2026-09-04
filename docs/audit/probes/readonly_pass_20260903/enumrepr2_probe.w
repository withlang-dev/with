use std.builtins.print_i32
enum Huge: i64:
    A = 7000000000
fn main:
    print_i32(if Huge.A == Huge.A: 1 else: 0)
