//! expect-stdout: 2
// §4.10 (#633): implicit-default HashSet is a real empty set.
use std.collections.HashSet
use std.builtins.print_i32
fn d() -> HashSet[i32]:
    ()
fn main:
    var s = d()
    s.insert(5)
    s.insert(6)
    s.insert(5)
    print_i32(s.len() as i32)
