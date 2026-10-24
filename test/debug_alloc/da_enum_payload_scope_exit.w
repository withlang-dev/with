//! expect-debug-alloc: leak count=0
// #693: a Drop-payload enum at PLAIN scope exit drops the payload exactly
// once. The moved-in payload temp must be consumed (reset-on-move + guard)
// by the variant ctor; the discard/match paths were always clean, which is
// why this cell existed nowhere until tools/drop_audit.w found the bug.
use std.builtins.print_i32
extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut c_void)
type R { id: i32, ptr: *mut u8, slot: *mut i32 }
impl Drop for R:
    fn drop(move self: Self):
        unsafe:
            *self.slot = *self.slot + self.id
            with_free(self.ptr)
fn mk(id: i32, slot: *mut i32) -> R:
    unsafe { R { id: id, ptr: with_alloc(16), slot: slot } }
enum E:
    Carry(R)
    Empty
fn go(slot: *mut i32):
    let a = E.Carry(mk(1, slot))
    let _keep = 0
fn main:
    var drops: i32 = 0
    let slot = &raw mut drops
    go(slot)
    print_i32(drops)
