//! skip: non-executable spec sketch for Section 4.8 — Tuples (formerly 25.36); contains pseudo-code for unimplemented feature work
// Spec test: Section 4.8 — Tuples (formerly 25.36)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: tuple construction and destructuring
fn test:
    let pair = (42, "hello")
    let (n, s) = pair
    assert(n == 42)

// PASS: tuple access by index
fn test:
    let t = (1, 2, 3)
    assert(t.0 == 1)
    assert(t.2 == 3)

// PASS: tuple return from function
fn divmod(a: i32, b: i32) -> (i32, i32): (a / b, a % b)
fn test:
    let (q, r) = divmod(17, 5)
    assert(q == 3)
    assert(r == 2)

// PASS: nested destructuring
fn test:
    let ((a, b), c) = ((1, 2), 3)
    assert(a == 1)
    assert(c == 3)

// PASS: tuples in for loops
fn test:
    let pairs = vec![(1, "a"), (2, "b")]
    for (n, s) in pairs:
        assert(n > 0)

// PASS: tuple is Copy when all elements are Copy
fn test:
    let t: (i32, bool) = (1, true)
    let t2 = t                    // copy
    assert(t.0 == 1)              // original still valid
