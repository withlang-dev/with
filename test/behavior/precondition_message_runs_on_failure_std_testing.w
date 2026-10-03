//! expect-stdout: message evaluated
//! expect-exit: 134
//! expect-stderr: testing.require failed

// D86 (§18.2, #1864): the `std.testing` form evaluates its owned message
// only on failure.
use std.testing

fn message() -> str:
    print("message evaluated")
    "testing.require failed"

fn main:
    testing.require(false, message())
    print("unreachable")
