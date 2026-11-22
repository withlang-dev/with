//! expect-debug-alloc: leak count=0
// #481/#641 (§8.3.2.5): TempArena's destructor runs reset() at scope exit —
// every recorded USER allocation is freed exactly once (no leak, no DOUBLE
// FREE), including after an explicit mid-scope reset() + further allocs. The
// two expected leaks are POD `List[i64]` backings (the one replaced by reset's
// re-init and the final one), which the narrow drop gate intentionally does
// not free (#608, same class as da_pod_vec).
use std.alloc

fn main:
    let temp = scratch_arena()
    with temp as mut arena:
        let p1 = arena.alloc(32)
        let p2 = arena.alloc(64)
        let _ = p1
        let _ = p2
        arena.reset()
        let p3 = arena.alloc(16)
        let _ = p3
    print("ok")
