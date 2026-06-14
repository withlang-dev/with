//! expect-check-fail: escaping closure cannot capture ephemeral references

use std.context

fn traced(ctx: implicit Context) -> i64:
    ctx.trace_id.value

fn make_reader() -> fn() -> i64:
    with active(default_context()):
        () => traced()

fn main:
    let reader = make_reader()
    let _ = reader()
