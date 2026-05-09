//! expect-stdout: ok

use std.alloc

fn main:
    let temp = scratch_arena()
    with temp as mut arena:
        let ptr = arena.alloc(16)
        let _ = ptr
        arena.reset()
    print("ok")
