//! expect-check-fail: not yet supported

// [A5] #607: moving a needs-drop (transitive-Drop, e.g. Vec[W]) field out of a struct
// via a `move self` receiver double-frees the shared buffer under the current
// non-consuming move model (the source local and the struct's field both free it).
// Rejected with an honest "not yet supported" diagnostic pending real move semantics
// (#607). When #607 lands, this flips back to a behavior test (count 1). This is the
// move-self form; see err_move_out_vec_field_{let,return} for the others.

type W { slot: *mut i32 }
impl Drop for W:
    fn drop(move self: Self):
        unsafe:
            *self.slot = *self.slot + 1

type Holder { values: Vec[W] }

fn Holder.into_values(move self: Holder) -> Vec[W]:
    self.values

fn main:
    print_i32(0)
