//! time probe 2: now() wall-clock epoch + now_ns()/clock_ticks monotonicity.
use std.time
use std.builtins.print_i64

fn main:
    let wall = now()
    print_i64(wall)
    assert(wall > 1752537600)
    assert(wall < 4102444800)
    let a = now_ns()
    let b = now_ns()
    assert(b >= a)
    let t = clock_ticks()
    assert(t >= a)
    print("ok")
