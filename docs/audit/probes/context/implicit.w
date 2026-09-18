// Audit probe: spec §7.3 implicit-Context example verbatim.
// Oracle: docs/with-specification.md §7.3 — `with active(default_context()):`
// must supply the implicit Context so trace_of() reads trace id 0.
use std.context.Context
use std.context.default_context
use std.builtins.print

fn trace_of(ctx: implicit Context) -> i64:
    ctx.trace_id.value

fn main:
    with active(default_context()):
        let id = trace_of()
        assert(id == 0)
    print("context-implicit-ok")
