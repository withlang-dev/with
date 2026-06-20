//! expect-stdout: ok

// A5: assigning a new Vec into a mut-self field drops the old Vec tail before
// replacing it, then drops the new Vec when the owner leaves scope.

type W { slot: *mut i32 }
impl Drop for W:
    fn drop(move self: Self):
        unsafe:
            *self.slot = *self.slot + 1

type Holder { values: Vec[W] }

fn make_values(slot: *mut i32) -> Vec[W]:
    let values: Vec[W] = Vec.new()
    values.push(W { slot: slot })
    values

fn Holder.replace_tail(mut self: Holder, slot: *mut i32):
    self.values = make_values(slot)

fn run(slot: *mut i32):
    let holder = Holder { values: make_values(slot) }
    holder.replace_tail(slot)

fn main:
    var count = 0
    run(&raw mut count)
    if count == 2:
        print("ok")
    else:
        print_i32(count)
