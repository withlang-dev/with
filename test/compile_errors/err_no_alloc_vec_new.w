//! expect-check-fail: List.new allocates here

use std.collections

@[no_alloc]
fn main:
    let v: List[i32] = List.new()
    v.len()
