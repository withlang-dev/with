//! expect-stdout: ok

// A5: moving a Vec field out through a move-self receiver transfers ownership
// to the returned Vec. The consumed owner must not also drop the moved field.

type W { slot: *mut i32 }
impl Drop for W:
    fn drop(move self: Self):
        unsafe:
            *self.slot = *self.slot + 1

type Holder { values: Vec[W] }

fn make_holder(slot: *mut i32) -> Holder:
    let values: Vec[W] = Vec.new()
    values.push(W { slot: slot })
    Holder { values: values }

fn Holder.into_values(move self: Holder) -> Vec[W]:
    self.values

fn run(slot: *mut i32):
    let holder = make_holder(slot)
    let values = holder.into_values()

fn main:
    var count = 0
    run(&raw mut count)
    if count == 1:
        print("ok")
    else:
        print_i32(count)
