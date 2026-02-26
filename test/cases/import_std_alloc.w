// Test: std.alloc import
use std.alloc

fn main -> i32:
    let arena = arena_new(128)
    let p = arena_alloc(arena, 64)
    assert(p != 0)
    arena_free(arena, p)

    let z = arena_alloc_zeroed(arena, 8, 8)
    assert(z != 0)
    arena_free(arena, z)
    arena_reset(arena)

    let pool = pool_new(32, 4)
    let q = pool_alloc(pool)
    assert(q != 0)
    pool_free(pool, q)
    0
