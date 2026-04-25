//! skip
// Spec test: Section 14.3, Invariant 5 — May-Suspend Analysis (formerly 25.67)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// FAIL: may_suspend function called while guard is live
fn helper:
    some_io().await

fn test_fail:
    let lock = Mutex.new(42)
    with lock.lock() as data:
        helper()                     // ERROR E0701: may_suspend function
                                     // called while @[no_await_guard] is live

// PASS: no suspension in guarded block
fn safe_helper(x: i32) -> i32: x * 2

fn test:
    let lock = Mutex.new(42)
    with lock.lock() as data:
        safe_helper(*data)           // OK: safe_helper is not may_suspend
