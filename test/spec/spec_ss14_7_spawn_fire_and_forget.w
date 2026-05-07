//! skip: non-executable spec sketch for Section 14.7 — Spawn Fire-and-Forget (formerly 25.74); contains pseudo-code for unimplemented feature work
// Spec test: Section 14.7 — Spawn Fire-and-Forget (formerly 25.74)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: spawn for fire-and-forget
fn test:
    spawn send_analytics("page_view")  // runs to completion, detached

// WARNING: let _ = task cancels immediately
fn test_bad:
    let _ = send_analytics("page_view") // WARNING: immediately cancelled!
