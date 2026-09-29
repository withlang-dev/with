//! expect-check-fail: this closure consumes its capture and may be invoked once, but `visit` invokes its parameter more than once

// Callback userdata cannot erase the call-once restriction of a closure:
// `visit` hands its callable to C as `each`'s userdata, and C calls the
// callback — and so the userdata — any number of times (§12.4, §16.2b.9).
use c_import("static inline int each(int (*visit)(void *, int), void *ctx) { visit(ctx, 7); return visit(ctx, 9); }")
c facade calls:
    fn each
        callback param 0 userdata param 1
fn invoke(context: &fn(i32) -> i32, value: i32) -> i32: context(value)
fn visit(callback: fn(i32) -> i32): each(invoke, callback)
fn main:
    let owned = "owned".clone()
    visit(value => { drop(owned); value })
