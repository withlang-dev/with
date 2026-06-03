//! expect-stdout: ok

// Spec test: Section 7.9 — NLL-Based @[no_await_guard] (formerly 25.82)

@[no_await_guard]
type LocalGuard {
    value: i32,
}

async fn work() -> i32:
    42

fn id_i32_ref(x: &i32) -> &i32:
    x

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

fn test_derived_view_last_use_before_await:
    let held = LocalGuard { value: 4 }
    let view = &held.value
    assert(*view == 4)
    let task = work()
    assert(task.await == 42)

fn test_call_returned_view_last_use_before_await:
    let held = LocalGuard { value: 5 }
    let view = id_i32_ref(&held.value)
    assert(*view == 5)
    let task = work()
    assert(task.await == 42)

fn test_owned_snapshot_before_await:
    let held = LocalGuard { value: 6 }
    let snapshot = held.value
    let task = work()
    assert(task.await == 42)
    assert(snapshot == 6)

fn main:
    test_last_use_before_await()
    test_explicit_drop_before_await()
    test_scoped_binding_before_await()
    test_derived_view_last_use_before_await()
    test_call_returned_view_last_use_before_await()
    test_owned_snapshot_before_await()
    print("ok")
