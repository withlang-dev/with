//! time probe 3: sleep_secs(1) actually blocks ~1s on the monotonic clock.
//! Bounds are deliberately wide (0.9s..5s) to avoid load flakiness while
//! still refuting a no-op or ms-vs-s unit slip (1000x either way fails).
use std.time
use std.builtins.print_i64

fn main:
    let t0 = now_ns()
    let rc = sleep_secs(1)
    let t1 = now_ns()
    assert(rc == 0)
    let dt = t1 - t0
    print_i64(dt)
    assert(dt >= 900000000)
    assert(dt <= 5000000000)
    print("ok")
