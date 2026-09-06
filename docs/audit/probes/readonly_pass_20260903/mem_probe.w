use std.mem
use std.builtins.print_i32
fn main:
    var x = 1
    let p = &x as *const i32 as *i8
    mem_set(p, 0, 4)
    print_i32(x)
