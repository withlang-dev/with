use std.builtins.print_i32
@[repr(C)]
type Mixed { a: u8, b: i64, c: u16, d: i32 }
fn main:
    print_i32(sizeof[Mixed]() as i32)
    print_i32(alignof[Mixed]() as i32)
    print_i32(sizeof[usize]() as i32)
    print_i32(sizeof[isize]() as i32)
