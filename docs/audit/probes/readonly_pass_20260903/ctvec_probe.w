use std.builtins.print_i32
comptime fn build() -> i32:
    var v: Vec[i32] = Vec.new()
    v.push(10)
    v.push(20)
    v.len() as i32 + v.get(0) + v.get(1)
fn main:
    print_i32(build())
    var w: Vec[i32] = Vec.new()
    w.push(10)
    w.push(20)
    print_i32(w.len() as i32 + w.get(0) + w.get(1))
