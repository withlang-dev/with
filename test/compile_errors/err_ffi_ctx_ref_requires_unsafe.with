//! expect-error: unsafe function call requires unsafe context

// §16.7/§16.11: ctx_ref is an unsafe fn (the caller asserts the pointer is a
// live T), so calling it outside an unsafe context is rejected.

use std.ffi

type S { x: i32 }

fn main:
    let ctx = box_ctx(S { x: 1 })
    let r = ctx_ref(ctx as *mut S)
    print("x")
