//! expect-check-fail: `override` marks a grant, and `rename` grants nothing: no proof can contradict it (§31.7)

// §31.7: `override` applies only to grants. A presentation states no fact
// about the library, so there is no proof for it to stand against.
use c_import("int engine_tick(int n);")

c contract engine:
    fn engine_tick
        override rename tick

fn main:
    print("unreachable")
