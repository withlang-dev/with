use std.builtins.print_i32
fn main:
    var v: Vec[i32] = Vec.new()
    var i = 0
    while i < 1000:
        v.push(i * 2)
        i = i + 1
    // force multiple grows; verify content integrity
    var sum: i64 = 0
    var j = 0
    while j < 1000:
        sum = sum + v.get(j) as i64
        j = j + 1
    print_i32(sum as i32)
    print_i32(v.len() as i32)
