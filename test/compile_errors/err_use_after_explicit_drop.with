//! expect-check-fail: use of moved value
// §2.4/#641b: explicit x.drop() consumes the binding; later use is an error.
use std.builtins.print_i32
var DROPS = 0
type W { id: i32 }
impl Drop for W:
    fn drop(move self: Self): DROPS = DROPS + 1

fn main:
    let w = W { id: 1 }
    w.drop()
    print_i32(w.id)
