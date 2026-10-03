//! expect-stdout: ok

// #605 + #606: destructuring a tuple of two Drop values moves both elements out
// into bindings; each must drop exactly once (total 2). The source tuple must be
// fully consumed so it does not also drop the moved-out elements (which would
// count 4) — the channel `let (tx, rx) = channel()` case is the real-world oracle.

type W { slot: *mut i32 }
impl Drop for W:
    fn drop(move self: Self):
        unsafe:
            *self.slot = *self.slot + 1

fn make(slot: *mut i32) -> (W, W):
    (W { slot: slot }, W { slot: slot })

fn run(slot: *mut i32):
    let (a, b) = make(slot)

fn main:
    var count = 0
    run(&raw mut count)
    if count == 2:
        print("ok")
    else:
        print_i32(count)
