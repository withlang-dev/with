use std.io

fn main:
    let v: Vec[i32] = Vec.new()
    v.push(11)
    v.push(22)
    print_str("in0=")
    print_int(v.get(0))
    print_str("\n")
    print_str("oob=")
    print_int(v.get(99))
    print_str("\n")
