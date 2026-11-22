//! expect-error: call to unsafe function pointer requires unsafe context

unsafe fn bump(p: *mut i32) -> Unit:
    *p = *p + 1

fn main:
    var x: i32 = 0
    let cb: unsafe extern "C" fn(*mut i32) -> Unit = bump
    cb(&raw mut x)
