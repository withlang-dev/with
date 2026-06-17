//! expect-error: cannot use unsafe fn where a safe function type is expected

unsafe fn bump(p: *mut i32) -> Unit:
    *p = *p + 1

fn main:
    let cb: extern "C" fn(*mut i32) -> Unit = bump
    print("x")
