//! expect-check-fail: userdata type must be Send and Sync
//! expect-check-fail: = help: wrap the shared state so it is Send and Sync: a Mutex or an Atomic in place of 'Context'

use c_import("static inline int apply(int (*visit)(void *, int), void *ctx) { return visit(ctx, 7); }")
use std.rc

c contract calls:
    fn apply
        callback param 0 userdata param 1
        callback_thread any

type Context { base: Rc[i32] }
fn observe(context: &Context, value: i32) -> i32: value

fn main:
    let context = Context { base: Rc.new(35) }
    apply(observe, context)
