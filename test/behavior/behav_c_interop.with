//! check-only

// Behavior test: C interop features (spec SS15.3, SS16.1)
// TODO: c"hello" string literals and c_import() not yet implemented.
// Tests extern fn, which is the current C interop mechanism.

extern fn getpid() -> i32

fn main:
    let pid = unsafe { getpid() }
    assert(pid >= 0)
