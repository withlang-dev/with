use std.builtins.print_i32
fn main:
    var v: Vec[i32] = Vec.new()
    var i = 0
    while i < 3000:
        v.push(i * 2 + 1)
        i = i + 1
    print_i32(v.len() as i32)
    print_i32(v.get(1023))
    print_i32(v.get(1024))
    print_i32(v.get(2999))
