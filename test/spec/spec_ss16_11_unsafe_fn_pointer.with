//! expect-stdout: ok

// §16.11 unsafe callable types: an unsafe fn coerces to an unsafe fn-pointer
// slot; a safe fn widens into one; calling the slot requires unsafe.

unsafe fn bump(p: *mut i32) -> Unit:
    *p = *p + 1

type RawCallback = unsafe extern "C" fn(*mut i32) -> Unit

fn main:
    var x: i32 = 5
    let cb: RawCallback = bump
    unsafe:
        cb(&raw mut x)
    if x == 6:
        print("ok")
    else:
        print("bad")
