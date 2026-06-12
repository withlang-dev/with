//! expect-stdout: ok

use std.alloc

@[no_alloc]
fn use_arena(mut scope: ArenaScope) -> i32:
    let ptr = scope.alloc(4)
    let value_ptr = ptr as *mut i32
    unsafe:
        *value_ptr = 42
        *value_ptr

fn main:
    let arena = arena_new(16)
    var scope = arena.scope()
    assert(use_arena(scope) == 42)
    print("ok")

