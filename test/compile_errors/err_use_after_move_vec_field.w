//! expect-check-fail: use of moved value

// #607: moving a needs-drop field out of a struct consumes it — a later use
// of the moved field is rejected (the runtime blank makes it safe; the
// diagnostic makes it a compile error rather than a silent empty value).

use std.builtins.print_i32
type W { slot: *mut i32 }
impl Drop for W:
    fn drop(move self: Self):
        unsafe:
            *self.slot = *self.slot + 1

type Holder { a: Vec[W] }

fn main:
    var c = 0
    let v: Vec[W] = Vec.new()
    v.push(W { slot: &raw mut c })
    var h = Holder { a: v }
    let m = move h.a
    let n = h.a.len()
    print_i32(n as i32)
