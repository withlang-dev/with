//! expect-stdout: ok

use std.alloc

async fn work() -> i32:
    42

fn test_explicit_drop_before_await:
    let arena = arena_new(64)
    var scope = arena.scope()
    let ptr = scope.alloc(8)
    assert(ptr as i64 != 0)
    assert(scope.allocation_count() == 1)
    drop(scope)
    let task = work()
    assert(task.await == 42)

fn test_with_scope_ends_before_await:
    let arena = arena_new(64)
    with arena.scope() as mut scope:
        let ptr = scope.alloc_zeroed(2, 4)
        assert(ptr as i64 != 0)
        assert(scope.allocation_count() == 1)
    let task = work()
    assert(task.await == 42)

fn test_scope_allocation_read_write:
    let arena = arena_new(64)
    var scope = arena.scope()
    let ptr = scope.alloc(4)
    let value_ptr = ptr as *mut i32
    unsafe:
        *value_ptr = 65
        assert(*value_ptr == 65)
    assert(scope.allocation_count() == 1)
    scope.reset()
    assert(scope.allocation_count() == 0)

fn main:
    test_explicit_drop_before_await()
    test_with_scope_ends_before_await()
    test_scope_allocation_read_write()
    print("ok")
