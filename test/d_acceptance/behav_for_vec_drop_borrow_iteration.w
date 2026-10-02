//! expect-stdout: ok

// Was test/compile_errors/err_consume_iter_vec_drop.w (#607: `for w in xs` on a
// Drop-element Vec rejected as "not yet supported"). Eric's #712 ruling landed
// spec §13 borrow iteration: `for w in xs` now iterates by view, each element
// drops exactly once when the Vec does, and the collection stays valid.

use std.builtins.print_i32
type W { tag: i32 }
impl Drop for W:
    fn drop(move self: Self):
        print_i32(self.tag)

fn main:
    let xs: Vec[W] = Vec.new()
    xs.push(W { tag: 1 })
    xs.push(W { tag: 2 })
    var total = 0
    for w in xs:
        total = total + w.tag
    assert(total == 3)
    print("ok")
