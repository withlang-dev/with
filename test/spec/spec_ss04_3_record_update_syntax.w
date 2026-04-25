//! skip
// Spec test: Section 4.3 — Record Update Syntax (formerly 25.21)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

type Point { x: f64, y: f64 } with Copy

// PASS: basic update
fn test:
    let p1 = Point { x: 1.0, y: 2.0 }
    let p2 = { p1 with x: 3.0 }
    assert(p2.x == 3.0)
    assert(p2.y == 2.0)
    assert(p1.x == 1.0)        // p1 still valid (Copy)

// PASS: update non-Copy (moves base)
type Entity { name: String, hp: i32, pos: Point }
fn test:
    let e = Entity { name: "hero", hp: 100, pos: Point { x: 0.0, y: 0.0 } }
    let e2 = { e with hp: 90 }
    // e is moved; e2 owns the String
    assert(e2.hp == 90)
    assert(e2.name == "hero")

// PASS: multiple field update
fn test:
    let p = Point { x: 1.0, y: 2.0 }
    let p2 = { p with x: 10.0, y: 20.0 }
    assert(p2.x == 10.0 && p2.y == 20.0)
