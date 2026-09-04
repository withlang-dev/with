use std.ffi
use std.builtins.print_i32
type Holder = ephemeral { r: &i32 }
fn main:
    let x = 42
    let h = Holder { r: &x }
    let ctx = box_ctx(h)
    let back: &Holder = unsafe { ctx_ref(ctx as *mut Holder) }
    print_i32(*back.r)
