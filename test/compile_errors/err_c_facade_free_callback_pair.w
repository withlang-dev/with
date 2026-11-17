//! expect-check-fail: a callback given with no userdata
//! expect-check-fail: = help: pass the userdata the callback receives, or None for both

use c_import("static inline int apply(int (*visit)(void *, int), void *ctx) { return visit ? visit(ctx, 7) : -1; }")

c contract calls:
    fn apply
        callback param 0 userdata param 1
        nullable param 0

fn observe(context: &i32, value: i32) -> i32: value

fn main:
    apply(Some(observe), None)
