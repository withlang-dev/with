use std.builtins.print_i32
enum Big: i64:
    A = 70000
    B = 90000
enum Small: u8:
    X = 1
    Y = 2
fn main:
    let b = Big.B
    print_i32(if b == Big.B: 1 else: 0)
    print_i32(sizeof[Big]() as i32)
    print_i32(sizeof[Small]() as i32)
