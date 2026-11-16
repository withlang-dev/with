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
    // #3031: a lane's test window is the machine's width unless one is asked
    // for; a 4-core, 16 GiB runner runs 4 at once, never 32.
    assert(build_graph_test_window_for(0, 4, 16 * gib) == 4)
    assert(build_graph_test_window_for(0, 64, 16 * gib) == 8)
    assert(build_graph_test_window_for(6, 4, 16 * gib) == 6)
    assert(build_graph_test_window_for(99, 4, 16 * gib) == 32)
    print("ok")
