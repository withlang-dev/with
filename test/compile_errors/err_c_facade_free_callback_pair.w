//! expect-check-fail: a callback given with no userdata

use c_import("static inline int apply(int (*visit)(void *, int), void *ctx) { return visit ? visit(ctx, 7) : -1; }")

c facade calls:
    fn apply
        callback param 0 userdata param 1
        nullable param 0

fn observe(context: &i32, value: i32) -> i32: value

fn main:
    apply(Some(observe), None)
