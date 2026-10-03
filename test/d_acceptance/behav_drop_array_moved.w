//! expect-stdout: ok

// #605 + #606: a non-Copy (Drop) value moved into an array element is MOVED, not
// copied, and the array drops it once. A copy would drop both the source and the
// element -> count 2 (double-free analogue).

type W { slot: *mut i32 }
impl Drop for W:
    fn drop(move self: Self):
        unsafe:
            *self.slot = *self.slot + 1

fn run(slot: *mut i32):
    let w = W { slot: slot }
    let a = [w]

fn main:
    var count = 0
    run(&raw mut count)
    if count == 1:
        print("ok")
    else:
        print_i32(count)
