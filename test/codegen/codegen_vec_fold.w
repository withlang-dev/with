//! expect-stdout: 10
use std.builtins.int_to_string
fn main:
    let v: List[i32] = List.new()
    v.push(1)
    v.push(2)
    v.push(3)
    v.push(4)
    let sum = v.fold(0, (acc, x) => acc + x)
    print(int_to_string(sum))
