//! expect-debug-alloc: leak count=0
// Regression: a Copy field read of a Drop struct must NOT suppress the struct's
// drop. `let _ = r.ptr` / `let p = r.ptr` previously marked the (Copy) field moved
// via cancel_scheduled_value_drop_for_receiver_expr, degrading r's whole-value
// Drop into a no-op partial drop -> leak.
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

fn discard_field(slot: *mut i32):
    let r = new_resource(slot)
    let _ = r.ptr            // Copy field read, discarded
    // r dropped (freed) at scope exit

fn bind_field(slot: *mut i32):
    let r = new_resource(slot)
    let p = r.ptr            // Copy field read into a binding
    let _ = p
    // r dropped (freed) at scope exit

fn main:
    var drops = 0
    discard_field(&raw mut drops)
    bind_field(&raw mut drops)
    print_i32(drops)         // 2
