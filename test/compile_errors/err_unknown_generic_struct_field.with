//! expect-check-fail: unknown field 'missing'

use std.result.ContextError
fn main:
    let err: ContextError[str] = ContextError { message: "outer", source: "inner" }
    let _ = err.missing
