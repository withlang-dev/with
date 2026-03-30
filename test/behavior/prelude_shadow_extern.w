//! expect-stdout: ok

// Test: local extern fn shadows prelude-provided function.
// The prelude provides println, but a local extern fn with a
// different name that we define as a regular fn should work.
// Here we shadow assert with our own version.

fn assert(cond: bool):
    if not cond:
        print("FAIL")

fn main:
    assert(true)
    print("ok")
