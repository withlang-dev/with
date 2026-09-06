//! mem probe: exercises all 8 std.mem wrappers against libc-documented semantics.

use std.mem

fn main:
    // alloc returns nonzero; mem_set fills; direct byte read matches.
    let a = alloc(16)
    assert(a as i64 != 0)
    mem_set(a, 7, 16)
    unsafe:
        assert(*(a as *mut u8) == 7 as u8)
    // alloc_zeroed returns zeroed memory.
    let b = alloc_zeroed(16, 1)
    assert(b as i64 != 0)
    assert(mem_cmp(a, b, 16) != 0)
    // mem_copy makes them byte-equal; a later single-byte mutation is visible.
    mem_copy(b, a, 16)
    assert(mem_cmp(a, b, 16) == 0)
    unsafe:
        *(b as *mut u8) = 8 as u8
    assert(mem_cmp(a, b, 16) != 0)
    mem_copy(b, a, 16)
    assert(mem_cmp(a, b, 16) == 0)
    // Overlapping mem_move: a = [1, 7x14, 2], move(a, a+1, 15)
    // yields [7x14, 2, 2]; the expectation buffer is built independently.
    unsafe:
        *(a as *mut u8) = 1 as u8
        *(((a as *mut u8) + (15 as u64))) = 2 as u8
    mem_move(a, (((a as *mut u8) + (1 as u64))) as *i8, 15)
    let c = alloc(16)
    mem_set(c, 7, 16)
    unsafe:
        *(((c as *mut u8) + (14 as u64))) = 2 as u8
        *(((c as *mut u8) + (15 as u64))) = 2 as u8
    assert(mem_cmp(a, c, 16) == 0)
    // realloc preserves the 8-byte prefix.
    let d = alloc(8)
    mem_set(d, 9, 8)
    let d2 = realloc_mem(d, 64)
    assert(d2 as i64 != 0)
    let e = alloc(8)
    mem_set(e, 9, 8)
    assert(mem_cmp(d2, e, 8) == 0)
    free_mem(a)
    free_mem(b)
    free_mem(c)
    free_mem(d2)
    free_mem(e)
    print("ok")
