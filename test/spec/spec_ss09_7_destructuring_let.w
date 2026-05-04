//! skip
// Spec test: Section 9.7 — Destructuring Let (formerly 25.39)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: tuple destructuring
fn test:
    let (a, b, c) = (1, 2, 3)
    assert(a + b + c == 6)

// PASS: struct destructuring
type Point { x: f64, y: f64 }
fn test:
    let p = Point { x: 3.0, y: 4.0 }
    let { x, y } = p
    assert(x == 3.0)

// PASS: rest pattern in struct
type User { name: str, email: str, age: i32 }
fn test:
    let u = User { name: "A", email: "a@b", age: 30 }
    let { name, .. } = u
    assert(name == "A")

// PASS: let-else: with Option
fn test:
    let opt: Option[i32] = Some(42)
    let Some(val) = opt else: return
    assert(val == 42)

// PASS: nested destructuring
fn test:
    let (a, { x, y }) = (1, Point { x: 2.0, y: 3.0 })
    assert(a == 1)
    assert(x == 2.0)
