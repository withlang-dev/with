//! expect-stdout: ok

use std.alloc

fn main:
    var arena = arena_new(32)
    let first = arena.alloc(8)
    let first_i = first as *mut i32
    unsafe:
        *first_i = 11
        assert(*first_i == 11)

    let mark = arena.mark()
    let second = arena.alloc(8)
    let second_i = second as *mut i32
    unsafe:
        *second_i = 22
        assert(*second_i == 22)

    arena.reset_to(mark)
    let reused = arena.alloc(8)
    assert(reused as i64 == second as i64)

    let big = arena.alloc(80)
    assert(big as i64 != 0)

    arena.reset()
    let again = arena.alloc(8)
    assert(again as i64 == first as i64)

    let zeroed = arena.alloc_zeroed(2, 4) as *mut i32
    unsafe:
        assert(*zeroed == 0)
    arena.drop()
    print("ok")
