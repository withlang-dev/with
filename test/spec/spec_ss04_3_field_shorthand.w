//! skip
// Spec test: Section 4.3 — Field Shorthand (formerly 25.34)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: field shorthand in construction
type Point { x: f64, y: f64 }
fn test:
    let x = 1.0
    let y = 2.0
    let p = Point { x, y }
    assert(p.x == 1.0)
    assert(p.y == 2.0)

// PASS: mixed shorthand and explicit
type User { name: str, email: str, active: bool }
fn test:
    let name = "Alice"
    let email = "alice@example.com"
    let u = User { name, email, active: true }
    assert(u.active)

// PASS: shorthand in record update
fn test:
    let u = User { name: "Alice", email: "a@b.com", active: true }
    let email = "new@b.com"
    let u2 = { u with email }
    assert(u2.email == "new@b.com")
