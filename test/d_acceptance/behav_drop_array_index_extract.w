//! expect-stdout: ok

// D27 supersedes #606's implicit index-extraction surface: `a[i]` observes.
// Both bindings are views, so the array remains the sole owner and drops its
// two elements exactly once.

use std.builtins.print_i32
type W { slot: *mut i32 }
impl Drop for W:
    fn drop(move self: Self):
        unsafe:
            *self.slot = *self.slot + 1

fn run(slot: *mut i32):
    let a = [W { slot: slot }, W { slot: slot }]
    let x = a[0]
    let y = a[1]
    assert(x.slot == slot)
    assert(y.slot == slot)

fn main:
    var count = 0
    run(&raw mut count)
    if count == 2:
        print("ok")
    else:
        print_i32(count)
