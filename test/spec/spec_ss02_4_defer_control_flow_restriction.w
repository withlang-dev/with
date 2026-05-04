//! skip
// Spec test: Section 2.4 — Defer Control Flow Restriction (formerly 25.73)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// FAIL: return inside defer
fn test_fail:
    defer: return 42                    // ERROR E0901: non-local control flow in defer

// FAIL: ? inside defer
fn test_fail:
    defer: conn.close()?                // ERROR E0901: ? in defer

// PASS: handle errors locally
fn test:
    defer: conn.close().unwrap_or(())   // OK: error handled locally
