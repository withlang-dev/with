use c_import("stdint.h")
use std.builtins.print_i32
fn main:
    print_i32(sizeof[c_longdouble]() as i32)
    print_i32(sizeof[c_long]() as i32)
