//! expect-error: call to unsafe function pointer requires unsafe context

// §16.11/§16.7: a c_import callback field with a raw-pointer signature is
// emitted as an unsafe fn pointer, so calling the slot requires unsafe.

use c_import("typedef struct Cb { int (*cb)(int *p); } Cb;")

unsafe fn handler(p: *mut i32) -> i32:
    *p

fn main:
    var c = Cb { cb: handler }
    var x: i32 = 0
    let r = c.cb(&raw mut x)
    print("x")
