//! expect-stdout: 60
use std.iter

fn main:
    let v: Vec[i32] = Vec.new()
    v.push(10)
    v.push(20)
    v.push(30)
    let iter = v.iter()
    let total = iter_sum(iter)
    print(int_to_string(total as i64))
