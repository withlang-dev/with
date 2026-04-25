//! skip
// Spec test: Section 10.4 — Default Operator `??` (formerly 25.38)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: basic default
fn test:
    let x: Option[i32] = None
    let y = x ?? 42
    assert(y == 42)

// PASS: chained defaults
fn test:
    let a: Option[i32] = None
    let b: Option[i32] = None
    let c: Option[i32] = Some(3)
    let result = a ?? b ?? c ?? 0
    assert(result == 3)

// PASS: default with early return
fn find(id: i32) -> Option[str]: None
fn get_or_fail(id: i32) -> Result[str, str]:
    let name = find(id) ?? return Err("not found")
    Ok(name)

fn test:
    assert(get_or_fail(1).is_err())
