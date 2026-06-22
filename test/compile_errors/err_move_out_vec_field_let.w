//! expect-check-fail: not yet supported

// [A5] #607: the let-binding form of moving a needs-drop Vec field out of a struct.
// `let m = h.a` copies the shared buffer into `m` but leaves the source local `pa`
// (and the struct's field) live → double-free. Rejected pending real move semantics
// (#607). See err_move_out_vec_field_{return,moveself} for the other consuming sites.

type W { tag: i32 }
impl Drop for W:
    fn drop(move self: Self):
        print_i32(self.tag)

type Holder { a: Vec[W], b: Vec[W] }

fn main:
    let pa: Vec[W] = Vec.new()
    pa.push(W { tag: 1 })
    let pb: Vec[W] = Vec.new()
    pb.push(W { tag: 2 })
    let h = Holder { a: pa, b: pb }
    let m = h.a
    let n = m.len()
