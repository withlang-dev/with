//! expect-check-fail: not yet supported

// [A5] #607: the return-tail form of moving a needs-drop Vec field out of a struct.
// `fn take(h: Holder) -> Vec[W]: h.a` returns the field's buffer while the struct
// (and its source) still own it → double-free. Rejected pending real move semantics
// (#607). See err_move_out_vec_field_{let,moveself} for the other consuming sites.

type W { tag: i32 }
impl Drop for W:
    fn drop(move self: Self):
        print_i32(self.tag)

type Holder { a: Vec[W] }

fn take(h: Holder) -> Vec[W]:
    h.a

fn main:
    print_i32(0)
