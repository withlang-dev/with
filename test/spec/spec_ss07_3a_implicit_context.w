//! expect-stdout: ok

use std.alloc
use std.context

fn make_context(id: i64) -> Context:
    Context {
        temp: scratch_arena(),
        logger: NoopLogger {},
        cancellation: CancellationToken { cancelled: false },
        trace_id: TraceId { value: id },
    }

fn trace_id(ctx: implicit Context) -> i64:
    ctx.trace_id.value

fn traced_sum(x: i64, ctx: implicit Context, extra: i64 = 1) -> i64:
    x + ctx.trace_id.value + extra

fn main:
    with active(make_context(7)):
        assert(trace_id() == 7)
        assert(trace_id(ctx: make_context(11)) == 11)
        assert(traced_sum(2) == 10)
        with nested(make_context(20)):
            assert(trace_id() == 20)
        assert(trace_id() == 7)
    print("ok")
