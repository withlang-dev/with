//! expect-debug-alloc: leak count=0
// #697: conditional move of a WHOLE Box local. On the moving path the local is
// reset to null; the scope-exit box drop must null-check before dropping the
// pointee. Was: SIGSEGV at scope exit (mir_emit_box_drop_place dereferenced
// the reset pointer with no runtime guard).
use std.box.Box
use std.builtins.print_i32
extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut u8) -> Unit

type Resource { ptr: *mut u8, slot: *mut i32 }
impl Drop for Resource:
    fn drop(move self: Self):
        unsafe:
            with_free(self.ptr)
            *self.slot = *self.slot + 1

fn new_resource(slot: *mut i32) -> Resource:
    unsafe { Resource { ptr: with_alloc(32), slot } }

fn take_box(x: Box[Resource]):
    let sink = x

fn run_box(cond: bool, slot: *mut i32):
    var b = Box.new(new_resource(slot))
    if cond:
        take_box(move b)
    print_i32(0)

fn main:
    var drops = 0
    run_box(true, &raw mut drops)
    assert(drops == 1)
    run_box(false, &raw mut drops)
    assert(drops == 2)
    print_i32(drops)
