//! expect-debug-alloc: leak count=0
// #697: conditional move of a whole Rc local. On the moving path the handle is
// reset to null; the scope-exit refcount drop must null-check before touching
// the strong count. Same class as the Box crash, refcount flavor.
use std.rc.Rc
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

fn take_rc(x: Rc[Resource]):
    let sink = x

fn run_rc(cond: bool, slot: *mut i32):
    var r = Rc.new(new_resource(slot))
    if cond:
        take_rc(move r)
    print_i32(0)

fn main:
    var drops = 0
    run_rc(true, &raw mut drops)
    assert(drops == 1)
    run_rc(false, &raw mut drops)
    assert(drops == 2)
    print_i32(drops)
