use std.ffi
use std.collections
use std.builtins.print_i32
fn main:
    let x = 42
    var v: Vec[&i32] = Vec.new()
    v.push(&x)
    let ctx = box_ctx(v)
    print_i32(ctx as i64 as i32)
