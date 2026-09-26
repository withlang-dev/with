//! expect-check-fail: cannot read `body` while `sink` is a live mutating view into it

// §12.4 (D62, #1691): the same through a method read of a captured Vec.
use std.builtins.print_i32
fn main:
    var body: Vec[i32] = Vec.new()
    let sink = k => body.push(k)
    sink(1)
    let n = body.len()
    sink(2)
    print_i32(n as i32)
