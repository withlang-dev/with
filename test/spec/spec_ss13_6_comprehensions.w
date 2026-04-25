//! skip
// Spec test: Section 13.6 — Comprehensions (formerly 25.27)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: basic comprehension
fn test:
    let squares = [x * x for x in 0..5]
    assert(squares == vec![0, 1, 4, 9, 16])

// PASS: comprehension with filter
fn test:
    let evens = [x for x in 0..10 if x % 2 == 0]
    assert(evens == vec![0, 2, 4, 6, 8])

// PASS: nested comprehension
fn test:
    let pairs = [(x, y) for x in 0..3 for y in 0..3 if x != y]
    assert(pairs.len() == 6)
