//! skip: non-executable spec sketch for Section 9.7 — Chained if let (formerly 25.94); contains pseudo-code for unimplemented feature work
// Spec test: Section 9.7 — Chained if let (formerly 25.94)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: chained if let bindings
fn test:
    let a: Option[i32] = Some(1)
    let b: Option[i32] = Some(2)
    var result = 0
    if let Some(x) = a, let Some(y) = b:
        result = x + y
    assert(result == 3)

// PASS: chain fails if any binding fails
fn test:
    let a: Option[i32] = Some(1)
    let b: Option[i32] = None
    var result = 0
    if let Some(x) = a, let Some(y) = b:
        result = x + y
    assert(result == 0)

// PASS: mixed boolean and let bindings
fn test:
    let users = vec![User { name: "Alice", active: true }]
    if let Some(user) = users.first(), user.active:
        assert(user.name == "Alice")
