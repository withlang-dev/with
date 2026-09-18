// Audit probe: std.context defaults + with_temp propagation.
// Oracle: docs/with-specification.md §7.3 — a fresh Context carries a temp
// arena, trace id 0, and an uncancelled token; with_temp preserves them.
use std.context.default_context
use std.builtins.print

fn main:
    let ctx = default_context()
    assert(ctx.trace_id.value == 0)
    assert(ctx.cancellation.cancelled == false)
    let ctx2 = ctx.with_temp()
    assert(ctx2.trace_id.value == 0)
    assert(ctx2.cancellation.cancelled == false)
    ctx.logger.info("probe-info")
    ctx.logger.warn("probe-warn")
    ctx.logger.error("probe-error")
    print("context-defaults-ok")
