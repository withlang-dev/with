//! expect-error: use of moved value

// #605: a non-Copy value moved into a tuple field must be consumed -- using it
// afterward is a use-after-move.

type W { id: i32 }
impl Drop for W:
    fn drop(move self: Self):
        print_i32(self.id)

fn main:
    let tmp = W { id: 5 }
    let t = (tmp, 9)
    print_i32(tmp.id)   // ERROR
