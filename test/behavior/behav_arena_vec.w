//! expect-stdout: ok

use std.alloc

fn main:
    var arena = arena_new(64)
    var xs: ArenaList[i32] = arena_list_new_in(&raw mut arena as *mut Arena)
    let xsp = &raw mut xs as *mut ArenaList[i32]
    unsafe:
        arena_list_push(xsp, 10)
        arena_list_push(xsp, 20)
        arena_list_push(xsp, 30)
        assert(arena_list_len(xsp as *const ArenaList[i32]) == 3)
        assert(arena_list_get(xsp as *const ArenaList[i32], 0) == 10)
        assert(arena_list_get(xsp as *const ArenaList[i32], 1) == 20)
        assert(arena_list_get(xsp as *const ArenaList[i32], 2) == 30)
    arena.drop()
    print("ok")
