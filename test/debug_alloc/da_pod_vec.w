//! expect-debug-alloc: leak count=0
use std.builtins.print_i32
fn main:
    let ns: List[i32] = List.new()
    ns.push(1)
    ns.push(2)
    print_i32(ns.len() as i32)
