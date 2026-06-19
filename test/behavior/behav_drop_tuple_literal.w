//! expect-stdout: ok

// #606: a Drop value constructed directly inside a tuple literal must be
// dropped when the tuple goes out of scope. A missing tuple-element drop
// leaks it (counter stays 0).

type W { slot: *mut i32 }
impl Drop for W:
    fn drop(move self: Self):
        unsafe:
            *self.slot = *self.slot + 1

fn run(slot: *mut i32):
    let t = (W { slot: slot }, 9)

fn main:
    var count = 0
    run(&raw mut count)
    if count == 1:
        print("ok")
    else:
        print_i32(count)
