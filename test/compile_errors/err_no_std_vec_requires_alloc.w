//! args: --no-std
//! expect-check-fail: Vec requires alloc

use std.collections

@[panic_handler]
fn on_panic -> Never: unreachable()

@[entry]
fn start -> i32:
    let v: Vec[i32] = Vec.new()
    v.len()
