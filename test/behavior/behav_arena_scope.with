//! expect-stdout: ok

use std.alloc

fn main:
    let arena = arena_new(16)
    var scope = arena.scope()
    let ptr = scope.alloc(4)
    assert(ptr as i64 != 0)
    let value_ptr = ptr as *mut i32
    unsafe:
        *value_ptr = 10
        assert(*value_ptr == 10)
    assert(scope.allocation_count() == 1)
    scope.reset()
    assert(scope.allocation_count() == 0)

    let zeroed = scope.alloc_zeroed(2, 4)
    assert(zeroed as i64 != 0)
    let zeroed_value = zeroed as *mut i32
    unsafe:
        assert(*zeroed_value == 0)
        *zeroed_value = 7
        assert(*zeroed_value == 7)
    assert(scope.allocation_count() == 1)
    print("ok")
