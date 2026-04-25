//! skip
// Spec test: Section 7.1 — With Type-Based Guard Inference (formerly 25.89)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: Scoped type auto-detected
fn test:
    let lock = Mutex.new(42)
    let val = with lock.read() as data:    // auto-detected as guard
        *data
    assert(val == 42)

// PASS: non-Scoped type → builder
fn test:
    let v = with Vec.new() as mut v:
        v.push(1)
        v.push(2)
    assert(v.len() == 2)
