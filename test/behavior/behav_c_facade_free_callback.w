//! expect-stdout: ok

// #1644: receiver presentation does not determine whether a callback
// contract is valid. Both C parameter orders infer U from the userdata.
use c_import("typedef int (*visit_fn)(void *, int);
static inline int apply(visit_fn visit, void *ctx, int n) { return visit(ctx, n); }
static inline int apply_reverse(void *ctx, int n, visit_fn visit) { return visit(ctx, n); }
static inline int maybe_apply(visit_fn visit, void *ctx) { return visit ? visit(ctx, 7) : (ctx ? -2 : -1); }
static inline void apply_void(visit_fn visit, void *ctx) { visit(ctx, 7); }
")

c facade calls:
    fn apply
        callback param 0 userdata param 1
    fn apply_reverse
        callback param 2 userdata param 0
        rename reversed
    fn maybe_apply
        callback param 0 userdata param 1
        nullable param 0
    fn apply_void
        callback param 0 userdata param 1

type Context { base: i32 }
fn add(context: &Context, value: i32) -> i32: context.base + value
fn collect(sink: &fn(i32) -> i32, value: i32) -> i32: sink(value)

fn main:
    let context = Context { base: 35 }
    assert(apply(add, context, 7) == 42)
    assert(apply((ctx, n) => ctx.base + n, context, 8) == 43)
    assert(reversed(context, 9, add) == 44)
    assert(maybe_apply(Some(add), Some(&context)) == 42)
    assert(maybe_apply(None, None) == -1)
    apply_void(add, context)
    assert(context.base == 35)
    // An ordinary closure carries a mutable capture safely through typed
    // userdata. The shared userdata is the callable, not a mutable Vec.
    var seen: Vec[i32] = Vec.new()
    let sink = value => { seen.push(value); 0 }
    assert(apply(collect, sink, 7) == 0)
    assert(apply(collect, sink, 9) == 0)
    assert(seen.len() == 2 and seen[0] == 7 and seen[1] == 9)
    print("ok")
