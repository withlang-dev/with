//! expect-check-fail: not yet supported

// [A5] #607: destructuring a Vec[Drop] field out of a by-value struct moves the field
// out (the binding owns the buffer while the struct still does) → double free. Rejected
// pending real move semantics; match a borrow (`match &h`) or move the whole struct.

type W { tag: i32 }
impl Drop for W:
    fn drop(move self: Self):
        print_i32(self.tag)

type H { items: Vec[W] }

fn main:
    let xs: Vec[W] = Vec.new()
    xs.push(W { tag: 1 })
    let h = H { items: xs }
    match h:
        H { items } => print_i32(items.len() as i32)
