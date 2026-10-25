//! expect-stdout: ok

// #2603: the build graph's lane pool is as wide as the machine, bounded by
// its memory: a lane is budgeted two gibibytes (stage2 peaks near 1.7 GiB),
// the width never drops below one lane and never exceeds 32. An 18-core
// container with 7.7 GiB got 18 lanes before and was killed at exit 137.

use BuildGraphRuntime

let gib: i64 = 1024 * 1024 * 1024

fn main:
    assert(build_graph_pool_width_for(18, 7 * gib + gib / 2) == 3)
    assert(build_graph_pool_width_for(12, 64 * gib) == 12)
    assert(build_graph_pool_width_for(1, 64 * gib) == 1)
    assert(build_graph_pool_width_for(64, 1024 * gib) == 32)
    assert(build_graph_pool_width_for(8, gib) == 1)
    // An unknown memory total (0) does not bound the width.
    assert(build_graph_pool_width_for(8, 0) == 8)
    print("ok")
