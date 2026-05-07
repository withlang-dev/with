//! skip: non-executable spec sketch for Section 7.9 — NLL-Based @[no_await_guard] (formerly 25.82); contains pseudo-code for unimplemented feature work
// Spec test: Section 7.9 — NLL-Based @[no_await_guard] (formerly 25.82)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// FAIL: guard live across .await via plain let binding
fn test_fail:
    let guard = lock.lock()        // @[no_await_guard] type
    fetch(url).await               // ERROR E0701: guard is live

// PASS: guard dropped before .await
fn test:
    let data = with lock.read() as d:
        d.clone()
    fetch(data.url).await          // OK: guard already dropped
