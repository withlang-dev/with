use std.builtins.print_i32
enum U32Neg: u32:
    A = 0
    B = -1
fn main:
    let x = U32Neg.B
    match x:
        U32Neg.A => print_i32(10)
        U32Neg.B => print_i32(20)
