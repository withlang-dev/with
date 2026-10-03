//! expect-stdout: ok

// #605 + #606: destructuring a NAMED tuple binding must consume the source so it
// is not also dropped. `let t = ...; let (a, b) = t` moves both elements out of t
// into a and b (drop once each = 2). If t is not consumed, t's value drop also
// frees its elements -> count 4 (double-free).

type W { slot: *mut i32 }
impl Drop for W:
    fn drop(move self: Self):
        unsafe:
            *self.slot = *self.slot + 1

fn make(slot: *mut i32) -> (W, W):
    (W { slot: slot }, W { slot: slot })

fn run(slot: *mut i32):
    let t = make(slot)
    let (a, b) = t

fn main:
    var count = 0
    run(&raw mut count)
    if count == 2:
        print("ok")
    else:
        print_i32(count)
