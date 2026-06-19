//! expect-error: use of moved value

// #605: a non-Copy value moved into a struct field must be consumed -- using it
// afterward is a use-after-move.

type W { id: i32 }
impl Drop for W:
    fn drop(move self: Self):
        print_i32(self.id)
type Holder { w: W }
fn main:
    let tmp = W { id: 5 }
    let h = Holder { w: tmp }
    print_i32(tmp.id)
