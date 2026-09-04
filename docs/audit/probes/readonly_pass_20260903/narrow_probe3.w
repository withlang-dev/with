use std.builtins.print_i32
type W { v: i64 }
extend W:
    fn get(self: &Self, n: i32) -> i32: n
fn main:
    let w = W { v: 1 }
    let big: i64 = 100000
    print_i32(w.get(big))
