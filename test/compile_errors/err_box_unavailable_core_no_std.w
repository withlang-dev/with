//! args: --no-std
//! expect-check-fail: Box requires alloc

use std.box

@[panic_handler]
fn on_panic -> Never: unreachable()

@[entry]
fn start -> i32:
    let boxed: Box[i32] = Box.new(7)
    let _ = boxed
    0
