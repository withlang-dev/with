//! expect-stdout: ok

use std.alloc

fn main:
    let temp = scratch_arena()
    with temp as mut arena:
        let ptr = arena.alloc(16)
        let _ = ptr
        arena.reset()
    let temp2 = scratch_arena()
    with temp2 as mut scoped:
        let ptr = scoped.alloc_zeroed(2, 8)
        let _ = ptr
    print("ok")
