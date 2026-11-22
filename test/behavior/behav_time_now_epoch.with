//! expect-stdout: ok

// #657: now() is whole seconds since the Unix epoch, not a monotonic
// nanosecond reading. 1752537600 = 2025-07-15; 4102444800 = 2100-01-01.
// now_ns() stays a monotonic nanosecond clock.

use std.time

fn main:
    let wall = now()
    assert(wall > 1752537600)
    assert(wall < 4102444800)

    let a = now_ns()
    let b = now_ns()
    assert(b >= a)
    print("ok")
