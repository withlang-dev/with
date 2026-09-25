//! expect-check-fail: calling this closure moves `owned` out of its capture

// Callback userdata cannot erase the call-once restriction of a closure.
use c_import("static inline int each(int (*visit)(void *, int), void *ctx) { visit(ctx, 7); return visit(ctx, 9); }")
c facade calls:
    fn each
        callback param 0 userdata param 1
fn invoke(context: &fn(i32) -> i32, value: i32) -> i32: context(value)
fn visit(callback: fn(i32) -> i32): each(invoke, callback)
fn main:
    let owned = "owned".clone()
    visit(value => { drop(owned); value })
