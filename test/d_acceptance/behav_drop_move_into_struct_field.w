//! expect-stdout: ok

// #605: moving a non-Copy (Drop) value into a struct field must MOVE it (single
// owner), not bitwise-copy it. A copy would drop both the source and the field
// -> the counter would reach 2 (double-free analogue).

type W { slot: *mut i32 }
impl Drop for W:
    fn drop(move self: Self):
        unsafe:
            *self.slot = *self.slot + 1

type Holder { w: W }

fn run(slot: *mut i32):
    let tmp = W { slot: slot }
    let h = Holder { w: tmp }

fn main:
    var count = 0
    run(&raw mut count)
    if count == 1:
        print("ok")
    else:
        print_i32(count)
