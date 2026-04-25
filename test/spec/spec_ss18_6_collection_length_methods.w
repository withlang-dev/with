//! skip
// Spec test: Section 18.6 — Collection Length Methods (formerly 25.47)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: .len32() returns i32
fn test:
    let items = vec![1, 2, 3, 4, 5]
    let count: i32 = items.len32()
    assert(count == 5)

// PASS: .len64() returns i64
fn test:
    let items = vec![1, 2, 3]
    let count: i64 = items.len64()
    assert(count == 3)

// PASS: .len() still returns usize
fn test:
    let items = vec![1, 2, 3]
    let count: usize = items.len()
    assert(count == 3)
