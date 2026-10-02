//! expect-stdout: 1
// §4.10 (#633): implicit-default Vec equals Vec.new() (real empty, correct
// elem_size), not a zeroed struct.
use std.builtins.print_i32
fn d() -> Vec[i32]:
    ()
fn main:
    var v = d()
    v.push(9)
    print_i32(v.len() as i32)
