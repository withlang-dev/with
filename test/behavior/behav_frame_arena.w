//! expect-stdout: ok

use std.alloc

fn main:
    var frame = frame_arena_new(32)
    let first = frame.alloc(8)
    let p0 = first as *mut i32
    unsafe:
        *p0 = 5
        assert(*p0 == 5)

    let big = frame.alloc(96)
    assert(big as i64 != 0)
    assert(frame.high_water() >= 96)

    frame.reset()
    let reused = frame.alloc(8)
    assert(reused as i64 == first as i64)

    frame.reset()
    let zeroed = frame.alloc_zeroed(1, 4) as *mut i32
    unsafe:
        assert(*zeroed == 0)
    frame.drop()
    print("ok")
