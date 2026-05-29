//! expect-stdout: ok

@[no_await_guard]
type LocalGuard {
    value: i32,
}

async fn async_value -> i32:
    21

fn safe_helper(x: i32) -> i32:
    x * 2

fn task_factory -> Task[i32]:
    async_value()

fn test_safe_call_under_guard:
    let held = LocalGuard { value: 21 }
    assert(safe_helper(held.value) == 42)

fn test_guard_detection_is_type_based:
    let lock_guard = 20
    assert(safe_helper(lock_guard) == 40)

fn test_async_call_without_await_returns_task:
    let task = task_factory()
    assert(task.await == 21)

fn main:
    test_safe_call_under_guard()
    test_guard_detection_is_type_based()
    test_async_call_without_await_returns_task()
    print("ok")
