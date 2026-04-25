//! skip
// Spec test: Section 14.7 — Ephemeral Task Cancellation (formerly 25.62)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// Ephemeral task drop blocks until fiber stops
async fn test:
    var data = vec![1, 2, 3]
    let _ = process(&mut data)       // ephemeral task: drop blocks
    // data is safe here — fiber guaranteed stopped

// Non-ephemeral task drop is cooperative (non-blocking)
async fn test:
    let _ = fetch("http://example.com")  // owned task: cooperative cancel
    // fetch fiber may still be running briefly
