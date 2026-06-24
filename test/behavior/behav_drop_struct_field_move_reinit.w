//! expect-stdout: ok

// A6: Drop must propagate through aggregate fields nested inside a struct. When
// a tuple field is reassigned, the old tuple elements drop; when the owner
// leaves scope, the replacement tuple elements drop.

type W { slot: *mut i32 }
impl Drop for W:
    fn drop(move self: Self):
        unsafe:
            *self.slot = *self.slot + 1

type Holder { pair: (W, W) }

fn Holder.replace_pair(mut self: Holder, slot: *mut i32):
    self.pair = (W { slot: slot }, W { slot: slot })

fn run(slot: *mut i32):
    let holder = Holder { pair: (W { slot: slot }, W { slot: slot }) }
    holder.replace_pair(slot)

fn main:
    var count = 0
    run(&raw mut count)
    if count == 4:
        print("ok")
    else:
        print_i32(count)
