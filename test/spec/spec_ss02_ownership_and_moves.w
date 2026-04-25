//! skip
// Spec test: Section 2 — Ownership and Moves (formerly 25.1)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: basic move
fn test:
    let a = Vec.new()
    let b = a
    b.push(1)

// FAIL: use after move
fn test:
    let a = Vec.new()
    let b = a
    a.push(1)            // ERROR: use of moved value

// PASS: copy type
fn test:
    let a: i32 = 5
    let b = a
    let c = a            // OK: Copy

// FAIL: use after move to function
fn takes(v: Vec[i32]): ()
fn test:
    let a = Vec.new()
    takes(a)
    a.len()              // ERROR: moved
