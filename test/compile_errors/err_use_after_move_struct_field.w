//! expect-check-fail: use of moved value

// A8: moving a Drop field out of a struct consumes that field path. Reading the
// same field afterward is a use-after-move.

type W { id: i32 }
impl Drop for W:
    fn drop(move self: Self):
        print_i32(self.id)

type Holder { item: W }

fn main:
    let holder = Holder { item: W { id: 7 } }
    let moved = holder.item
    print_i32(holder.item.id)
