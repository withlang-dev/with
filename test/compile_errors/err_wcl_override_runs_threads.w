//! expect-check-fail: `override` marks a grant, and `runs threads` grants nothing: no proof can contradict it (§31.7)

// §31.7: at a contract's own level `override` marks `runs no threads`, the
// grant. `runs threads` is the restriction.
use c_import("int engine_tick(int n);")

c contract engine:
    override runs threads
    fn engine_tick

fn main:
    print("unreachable")
