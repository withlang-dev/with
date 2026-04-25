//! skip
// Spec test: Section 4.2.7 — Chained Comparisons (formerly 25.102)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: ordered comparisons chain
fn test:
    let x = 5
    assert(0 < x < 10)
    assert(not (0 < x < 4))
    assert(5 <= x <= 5)

// FAIL: equality does not chain
fn test:
    let x = 1
    x == x == true     // ERROR
