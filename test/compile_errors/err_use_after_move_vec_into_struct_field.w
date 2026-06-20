//! expect-check-fail: use of moved value

// A5/#605: moving a Vec into a struct field transfers ownership. The source Vec
// cannot be used afterward once Vec has real Drop semantics.

type W { id: i32 }
impl Drop for W:
    fn drop(move self: Self):
        print_i32(self.id)

type Holder { items: Vec[W] }

fn main:
    let values: Vec[W] = Vec.new()
    values.push(W { id: 1 })
    let holder = Holder { items: values }
    values.push(W { id: 2 })
