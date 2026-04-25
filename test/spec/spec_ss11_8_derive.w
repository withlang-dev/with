//! skip
// Spec test: Section 11.8 — Derive (formerly 25.40)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: explicit derive
@[derive(Eq, Hash, Debug, Clone)]
type Color { r: u8, g: u8, b: u8 }
fn test:
    let a = Color { r: 255, g: 0, b: 0 }
    let b = Color { r: 255, g: 0, b: 0 }
    assert(a == b)

// PASS: derive(all) on Copy-eligible type
@[derive(all)]
type Vec2 { x: f64, y: f64 }
fn test:
    let a = Vec2 { x: 1.0, y: 2.0 }
    let b = a              // Copy (derived)
    assert(a.x == b.x)    // both valid

// PASS: derive(all) on non-Copy type
@[derive(all)]
type Name { first: str, last: str }
fn test:
    let a = Name { first: "A", last: "B" }
    let b = a.clone()     // Clone (derived), not Copy
    assert(b.first == "A")

// FAIL: explicit derive on ineligible type
@[derive(Copy)]
type Buffer { data: Vec[u8] }   // ERROR: field `data` is not Copy
