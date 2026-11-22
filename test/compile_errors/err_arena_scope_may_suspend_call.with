//! expect-error: E0701

use std.alloc

async fn work() -> i32:
    42

fn helper() -> i32:
    let task = work()
    task.await

fn main:
    let arena = arena_new(64)
    let scope = arena.scope()
    let value = helper()
    assert(scope.allocation_count() == 0)
    assert(value == 42)
