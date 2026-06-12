//! expect-error: E0701

use std.alloc

async fn work() -> i32:
    42

async fn main:
    let arena = arena_new(64)
    with arena.scope() as mut scope:
        let task = work()
        let value = task.await
        assert(scope.allocation_count() == 0)
        assert(value == 42)
