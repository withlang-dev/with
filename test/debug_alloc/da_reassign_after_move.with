//! expect-debug-alloc: leak count=0

// #614 (drop-elaboration "Dead" arm). `r` owns a heap allocation freed in drop.
// `take(r)` consumes r1 (frees r1.ptr); `r = new_resource()` must NOT free r1.ptr
// again — it was already moved out. Before the fix, the drop-before-overwrite at
// the reassignment freed the moved-out pointer a second time → DOUBLE FREE. The
// allocator is the oracle: a double-free fails this test; leak count must be 0.

use std.builtins.print_i32
extern fn with_alloc(size: i64) -> *mut u8
extern fn with_free(ptr: *mut c_void)

type Resource { ptr: *mut u8, slot: *mut i32 }
impl Drop for Resource:
    fn drop(move self: Self):
        unsafe:
            with_free(self.ptr)
            *self.slot = *self.slot + 1

fn new_resource(slot: *mut i32) -> Resource:
    unsafe { Resource { ptr: with_alloc(32), slot } }

fn take(r: Resource): ()

fn main:
    var drops = 0
    // straight-line reassign-after-move (#614): r1 freed once by take, the
    // reassignment must not free it again.
    var r = new_resource(&raw mut drops)
    take(r)
    r = new_resource(&raw mut drops)
    // moved-then-reinitialized in a loop too (the #613 case #614 unblocked).
    var i = 0
    while i < 3:
        take(r)
        r = new_resource(&raw mut drops)
        i = i + 1
    take(r)
    print_i32(drops)
