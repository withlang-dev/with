//! expect-check-fail: Vec.new allocates here

use std.collections

@[no_alloc]
fn main:
    let v: Vec[i32] = Vec.new()
    v.len()
