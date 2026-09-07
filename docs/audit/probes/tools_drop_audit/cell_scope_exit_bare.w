use std.builtins.print_i32
use std.box
use std.rc
extern fn with_alloc(size: i64) -> *i8
extern fn with_free(ptr: *i8) -> Unit
type R { id: i32, ptr: *i8, slot: *mut i32 }
impl Drop for R:
    fn drop(move self: Self):
        unsafe:
            *self.slot = *self.slot + self.id
            with_free(self.ptr)
fn mk(id: i32, slot: *mut i32) -> R:
    unsafe { R { id: id, ptr: with_alloc(16), slot: slot } }
fn go(slot: *mut i32):
    let a = mk(1, slot)
    let _keep = 0
fn main:
    var drops: i32 = 0
    let slot = &raw mut drops
    go(slot)
    print_i32(drops)
