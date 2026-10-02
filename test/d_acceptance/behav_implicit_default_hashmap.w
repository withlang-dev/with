//! expect-stdout: 2
// §4.10 (#633): a fall-through function returning HashMap yields a real empty
// map (was a zeroed struct with null buckets that SEGFAULTed on use).
use std.collections.HashMap
use std.builtins.print_i32
fn d() -> HashMap[str, i32]:
    ()
fn main:
    var m = d()
    m.insert("a", 1)
    m.insert("b", 2)
    print_i32(m.len() as i32)
