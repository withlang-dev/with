//! skip: non-executable spec sketch for Section 14.16 — ScopedSend (formerly 25.63); contains pseudo-code for unimplemented feature work
// Spec test: Section 14.16 — ScopedSend (formerly 25.63)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: scoped thread can use &mut local
fn test:
    var data = vec![1, 2, 3]
    scope s =>
        s.spawn(() => data.push(4))     // OK: &mut data is ScopedSend
    assert(data.len() == 4)

// PASS: async scope can track ephemeral tasks
async fn test:
    var data = vec![1, 2, 3]
    async scope s =>
        s.track(process(&mut data))  // OK: ScopedSend
    assert(data.len() > 0)

// FAIL: unscoped thread.spawn_os rejects ephemeral
fn test_fail:
    var data = vec![1, 2, 3]
    thread.spawn_os(() => data.push(4)) // ERROR: &mut Vec is not Send
