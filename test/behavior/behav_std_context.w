//! expect-stdout: ok

use std.context

fn traced(stdctx: implicit Context) -> i64:
    stdctx.trace_id.value

fn main:
    let base = default_context()
    with active(base):
        assert(traced() == 0)
    print("ok")
