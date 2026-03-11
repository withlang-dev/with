//! check-only

// Behavior test: C interop features (spec SS15.3, SS16.1)
// TODO: c"hello" string literals and c_import() not yet implemented.
// Tests extern fn, which is the current C interop mechanism.

extern fn with_str_len(s: str) -> i64

fn main:
    let n = with_str_len("hello")
    assert(n == 5)
