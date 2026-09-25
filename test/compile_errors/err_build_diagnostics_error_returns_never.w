//! expect-check-fail: unreachable code
use std.build

// The native implementation exits; the comptime implementation aborts
// evaluation. Neither returns to execute a caller's cleanup or fallback.
fn fatal(diag: &Diagnostics):
    diag.error("fatal")
    print("unreachable")

fn main:
    print("unused")
