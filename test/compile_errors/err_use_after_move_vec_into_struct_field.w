//! expect-check-fail: use of moved value

// A5/#605: moving a List into a struct field transfers ownership. The source List
// cannot be used afterward once List has real Drop semantics.

use std.builtins.print_i32
type W { id: i32 }
impl Drop for W:
    fn drop(move self: Self):
        print_i32(self.id)

type Holder { items: List[W] }

fn main:
    let values: List[W] = List.new()
    values.push(W { id: 1 })
    let holder = Holder { items: values }
    values.push(W { id: 2 })
