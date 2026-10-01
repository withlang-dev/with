//! expect-debug-alloc: leak count=0
// D16 (rvalue-uniform `move`): moving into a callee whose parameter only
// borrows (&T) still MOVES — the value becomes a statement temporary
// and is destroyed at the end of the call statement, not at scope exit. The
// assert directly after the call pins the timing: before D16 the drop was
// silently deferred to scope exit and drops was still 0 here.
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

fn borrows(x: &Resource):
    let _k = x.ptr

fn main:
    var drops = 0
    var r = new_resource(&raw mut drops)
    borrows(move r)
    assert(drops == 1)
    print_i32(drops)
