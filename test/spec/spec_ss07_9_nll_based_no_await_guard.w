//! expect-stdout: ok

// Spec test: Section 7.9 — NLL-Based @[no_await_guard] (formerly 25.82)

@[no_await_guard]
type LocalGuard {
    value: i32,
}

async fn work() -> i32:
    42

fn test_last_use_before_await:
    let held = LocalGuard { value: 1 }
    assert(held.value == 1)
    let task = work()
    assert(task.await == 42)

fn test_explicit_drop_before_await:
    let held = LocalGuard { value: 2 }
    assert(held.value == 2)
    drop(held)
    let task = work()
    assert(task.await == 42)

fn test_scoped_binding_before_await:
    with LocalGuard { value: 3 } as held:
        assert(held.value == 3)
    let task = work()
    assert(task.await == 42)

fn main:
    test_last_use_before_await()
    test_explicit_drop_before_await()
    test_scoped_binding_before_await()
    print("ok")
