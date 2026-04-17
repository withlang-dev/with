//! expect-check-fail: expected identifier
// Many cascading field-position errors must not crash the renderer.
// If the parser advances after emit_error (or the caller breaks the
// loop on failure), the compiler should emit several diagnostics and
// exit 1 cleanly, even when the whole pattern is malformed.
fn main:
    let g = Foo { 1 2 3 4 5 6 7 8 9 10 }
