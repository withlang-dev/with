//! expect-stdout: ok

// #605 + #606: a non-Copy (Drop) value moved into a tuple field must be MOVED
// (single owner), not bitwise-copied, AND the tuple must drop it once. A copy
// without a tuple-element drop happens to count 1 today by accident; once the
// tuple drops its element, the source must be consumed or the counter reaches 2
// (double-free analogue).

type W { slot: *mut i32 }
impl Drop for W:
    fn drop(move self: Self):
        unsafe:
            *self.slot = *self.slot + 1

fn run(slot: *mut i32):
    let tmp = W { slot: slot }
    let t = (tmp, 9)

fn main:
    var count = 0
    run(&raw mut count)
    if count == 1:
        print("ok")
    else:
        print_i32(count)
