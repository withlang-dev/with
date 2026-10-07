//! expect-check-fail: c_import symbol 'maybe_apply' was omitted: inline body needs the layout of 'flags'
// (it needs the layout of a bitfield record, imported opaque, #1417)
// must be a compile error naming the function and the reason (#2244).
use c_import("typedef int (*visit_fn)(void *, int);
struct flags { unsigned a : 3; unsigned b : 5; };
static inline int maybe_apply(visit_fn visit, void *ctx) { struct flags f; f.a = 1; return visit ? visit(ctx, (int)f.a) : -1; }
")

c facade calls:
    fn maybe_apply
        callback param 0 userdata param 1
        nullable param 0

type Context { base: i32 }
fn add(context: &Context, value: i32) -> i32: context.base + value

fn main:
    let context = Context { base: 35 }
    print(maybe_apply(Some(add), Some(&context)))
