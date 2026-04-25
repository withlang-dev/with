//! skip
// Spec test: Section 4.2 — Numerics (formerly 25.19)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// RUNTIME PANIC (debug): overflow
fn test:
    let x: u8 = 255
    let y = x + 1                  // panic

// PASS: wrapping
fn test:
    let x: u8 = 255
    assert(x +% 1 == 0)

// PASS: implicit widening
fn test:
    let x: i32 = 42
    let y: i64 = x                 // OK

// FAIL: implicit narrowing
fn test:
    let x: i64 = 42
    let y: i32 = x                 // ERROR
