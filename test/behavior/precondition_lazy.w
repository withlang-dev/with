//! expect-stdout: ok

// Test: lazy message evaluation.
// The message expression must NOT be evaluated when the condition is true.

fn side_effect() -> str:
    print("SHOULD NOT PRINT")
    "message"

fn main:
    // If lazy evaluation works, side_effect() is never called
    require(true, side_effect())
    check(true, side_effect())
    print("ok")
