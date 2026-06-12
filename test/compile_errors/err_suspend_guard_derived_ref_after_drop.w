//! expect-error: view 'view' may outlive its origin 'held'

// The derived-ref-after-drop defect is now diagnosed by the general
// view-origin rule before the E0701 suspend-guard check runs (the
// view-deps analysis previously dropped deps on realloc and missed
// this). E0701's primary coverage lives in the sibling fixtures.

@[no_await_guard]
type Guard {
    value: i32,
}

async fn work() -> i32:
    42

async fn main:
    let held = Guard { value: 1 }
    let view = &held.value
    drop(held)
    let t = work()
    let value = t.await
    assert(*view == value - 41)
