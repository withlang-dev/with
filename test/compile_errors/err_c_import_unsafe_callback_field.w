//! expect-error: call to unsafe function pointer requires unsafe context

// §16.11/§16.7: a c_import callback field with a raw-pointer signature is
// emitted as an unsafe fn pointer, so calling the slot requires unsafe.

use c_import("typedef struct Cb { int (*cb)(int *p); } Cb;")

unsafe fn handler(p: *mut i32) -> i32:
    *p

fn main:
    // D102: the field is `Option` of the unsafe pointer; the call through
    // it still needs the unsafe context.
    var c = Cb { cb: Some(handler) }
    var x: i32 = 0
    let r = c.cb.unwrap()(&raw mut x)
    print("x")
