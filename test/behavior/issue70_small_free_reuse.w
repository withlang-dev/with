//! expect-stdout: ok

use std.mem

fn main:
    let first = alloc(64)
    assert(first as i64 != 0)
    free_mem(first)

    let second = alloc(64)
    assert(second as i64 == first as i64)
    free_mem(second)

    let dirty = alloc(64)
    unsafe:
        *(dirty as *mut u8) = 123 as u8
    free_mem(dirty)

    let zeroed = alloc_zeroed(1, 64)
    unsafe:
        assert(*(zeroed as *mut u8) == 0 as u8)
    free_mem(zeroed)

    print("ok")
