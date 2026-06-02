//! expect-check-fail: unknown field 'missing'

fn main:
    let err: ContextError[str] = ContextError { message: "outer", source: "inner" }
    let _ = err.missing
