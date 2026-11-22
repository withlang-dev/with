//! args: --no-std
//! expect-check-fail: List requires alloc

use std.collections

@[panic_handler]
fn on_panic -> Never: unreachable()

@[entry]
fn start -> i32:
    let v: List[i32] = List.new()
    v.len()
