//! skip
// Spec test: Section 9.6 — Backward Application (formerly 25.29)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: basic backward application
fn double(x: i32) -> i32: x * 2
fn test:
    let result = double <| 5
    assert(result == 10)

// PASS: chained backward application (right-associative)
fn add1(x: i32) -> i32: x + 1
fn test:
    let result = add1 <| double <| 3
    assert(result == 7)      // add1(double(3)) = add1(6) = 7
