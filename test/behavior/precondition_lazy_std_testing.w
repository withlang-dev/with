//! expect-stdout: ok

// D86 (§18.2, #1864): the `std.testing` forms of `assert`, `require` and
// `check` are compiler-known forms too, reached through the namespace or
// imported by name: the message is evaluated only on failure.
use std.testing
use std.testing.require

fn side_effect() -> str:
    print("SHOULD NOT PRINT")
    "message"

fn main:
    testing.assert(true, side_effect())
    testing.require(true, side_effect())
    testing.check(true, side_effect())
    require(true, side_effect())
    print("ok")
