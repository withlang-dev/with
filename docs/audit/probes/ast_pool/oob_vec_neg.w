use std.io

fn main:
    let v: Vec[i32] = Vec.new()
    v.push(7)
    print_str("neg=")
    print_int(v.get(-1))
    print_str("\n")
