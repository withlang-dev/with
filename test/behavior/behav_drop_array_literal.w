//! expect-stdout: ok

// #606: Drop values constructed inside an array literal must be dropped when the
// array goes out of scope (3 elements -> 3 drops). A missing array element-drop
// leaks them (counter stays 0).

type W { slot: *mut i32 }
impl Drop for W:
    fn drop(move self: Self):
        unsafe:
            *self.slot = *self.slot + 1

fn run(slot: *mut i32):
    let a = [W { slot: slot }, W { slot: slot }, W { slot: slot }]

fn main:
    var count = 0
    run(&raw mut count)
    if count == 3:
        print("ok")
    else:
        print_i32(count)
