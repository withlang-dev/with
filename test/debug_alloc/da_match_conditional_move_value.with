//! expect-debug-alloc: leak count=0
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

fn run_implicit(cond: bool, slot: *mut i32):
    let r = new_resource(slot)
    match cond:
        true => take(r)
        false => ()

fn run_explicit(cond: bool, slot: *mut i32):
    let r = new_resource(slot)
    match cond:
        true => take(move r)
        false => ()

fn main:
    var drops = 0
    run_implicit(true, &raw mut drops)
    run_implicit(false, &raw mut drops)
    run_explicit(true, &raw mut drops)
    run_explicit(false, &raw mut drops)
    print_i32(drops)
