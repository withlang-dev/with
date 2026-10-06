//! expect-stdout: ok

use std.alloc

fn main:
    var arena = arena_new(64)
    var xs: ArenaVec[i32] = arena_vec_new_in(&raw mut arena as *mut Arena)
    let xsp = &raw mut xs as *mut ArenaVec[i32]
    unsafe:
        arena_vec_push(xsp, 10)
        arena_vec_push(xsp, 20)
        arena_vec_push(xsp, 30)
        assert(arena_vec_len(xsp as *const ArenaVec[i32]) == 3)
        assert(arena_vec_get(xsp as *const ArenaVec[i32], 0) == 10)
        assert(arena_vec_get(xsp as *const ArenaVec[i32], 1) == 20)
        assert(arena_vec_get(xsp as *const ArenaVec[i32], 2) == 30)
    arena.drop()
    print("ok")
