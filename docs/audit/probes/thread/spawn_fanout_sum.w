//! thread probe 3: fan-out of 4 threads with disjoint constant results.
//! Race-free by construction: each thread returns its own constant, the
//! parent sums after joining all four. Sum is schedule-independent.
use std.thread

fn main:
    let h1 = spawn_os(() => 10)
    let h2 = spawn_os(() => 20)
    let h3 = spawn_os(() => 30)
    let h4 = spawn_os(() => 40)
    let total = join(h1) + join(h2) + join(h3) + join(h4)
    assert(total == 100)
    print("ok")
