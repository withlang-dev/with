//! expect-error: unsafe function call requires unsafe context

unsafe fn write_ptr(p: *mut i32):
    *p = 2

fn main:
    var x = 1
    write_ptr(&raw mut x)
