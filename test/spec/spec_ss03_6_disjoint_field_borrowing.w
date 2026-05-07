//! skip: non-executable spec sketch for Section 3.6 — Disjoint Field Borrowing (formerly 25.5); contains pseudo-code for unimplemented feature work
// Spec test: Section 3.6 — Disjoint Field Borrowing (formerly 25.5)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

type Pair { a: Vec[i32], b: Vec[i32] }

// PASS: distinct fields
fn test(p: &mut Pair):
    let a = &mut p.a
    let b = &mut p.b
    a.push(1); b.push(2)

// FAIL: same field twice
fn test(p: &mut Pair):
    let a1 = &mut p.a
    let a2 = &mut p.a     // ERROR

// PASS: nested disjoint
type Deep { inner: Pair }
fn test(d: &mut Deep):
    let a = &mut d.inner.a
    let b = &mut d.inner.b
    a.push(1); b.push(2)

// FAIL: field: whole struct
fn test(p: &mut Pair):
    let a = &mut p.a
    let whole = &p         // ERROR: overlaps p.a
