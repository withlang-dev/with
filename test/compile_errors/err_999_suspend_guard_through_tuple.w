//! expect-error: E0701

// #999: a guarded view carried inside a tuple keeps its guard. The
// provenance pass gave an aggregate no origins, so `(view, 42)` crossed the
// await with no E0701, while the view alone is refused
// (err_suspend_guard_derived_ref_copy.w).
@[no_await_guard]
type Guard {
    value: i32,
}

async fn work() -> i32:
    42

async fn main:
    let held = Guard { value: 1 }
    let view = &held.value
    let pair = (view, 42)
    let t = work()
    let value = t.await
    let v0: &i32 = pair.0
    assert(*v0 == value - 41)
