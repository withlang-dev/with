use std.builtins.print_i32
enum U8Big: u8:
    A = 1
    B = 300
fn main:
    let x = U8Big.B
    print_i32(x as i32)
    match x:
        U8Big.A => print_i32(10)
        U8Big.B => print_i32(20)
