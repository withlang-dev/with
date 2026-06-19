//! expect-stdout: ok

// #606: Option is a generic enum; its Some payload must drop when the Option
// drops without being unwrapped.

type W { slot: *mut i32 }
impl Drop for W:
    fn drop(move self: Self):
        unsafe:
            *self.slot = *self.slot + 1

fn run(slot: *mut i32):
    let o = Some(W { slot: slot })

fn main:
    var count = 0
    run(&raw mut count)
    if count == 1:
        print("ok")
    else:
        print_i32(count)
