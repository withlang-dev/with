//! skip
// Spec test: Section 14.7 — Ephemeral Task OS Thread Restriction (formerly 25.86)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// FAIL: ephemeral task on bare OS thread
fn test_fail:
    thread.spawn_os(() =>
        var data = vec![1, 2, 3]
        let task = process(&mut data)  // ERROR: ephemeral task in OS thread
    )

// PASS: ephemeral task inside fiber (async context)
async fn test:
    var data = vec![1, 2, 3]
    let task = process(&mut data)      // OK: inside async context
    task.await
