//! expect-stdout: 405

use std.builtins.print_i32
type Forwarder {}

fn Forwarder.pair(mut self: Self, a: i32, b: i32): a * 100 + b
fn Forwarder.forward(mut self: Self, a: i32, b: i32, c: i32, d: i32, e: i32): self.pair(d, e)

fn main:
    var f = Forwarder {}
    print_i32(f.forward(1, 2, 3, 4, 5))
