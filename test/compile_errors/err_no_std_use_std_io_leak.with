//! args: --no-std --alloc
//! expect-check-fail: std.io requires std

use std.io

@[global_allocator]
global ALLOC: i32 = 0

@[panic_handler]
fn on_panic -> Never: unreachable()

@[entry]
fn start -> i32:
    0
