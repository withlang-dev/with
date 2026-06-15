//! args: --no-std
//! expect-check-fail: Rc requires alloc

use std.rc

@[panic_handler]
fn on_panic -> Never: unreachable()

@[entry]
fn start -> i32:
    let rc = Rc.new(7)
    let arc = Arc.new(9)
    let _ = rc
    let _ = arc
    0
