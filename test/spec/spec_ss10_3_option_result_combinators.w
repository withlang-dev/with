//! skip
// Spec test: Section 10.3, 10.4 — Option/Result Combinators (formerly 25.22)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: option chaining
fn test:
    let x: Option[i32] = Some(5)
    let y = x.map(n => n * 2).unwrap_or(0)
    assert(y == 10)

// PASS: and_then chains
fn test:
    let result = Some(10)
        .filter(x => x > 5)
        .and_then(x => if x < 20 then Some(x) else None)
        .unwrap_or(0)
    assert(result == 10)

// PASS: result map_err
fn test:
    let r: Result[i32, String] = Err("bad")
    let r2 = r.map_err(s => s.len())
    assert(r2 == Err(3))

// PASS: option on None
fn test:
    let x: Option[i32] = None
    let y = x.map(n => n * 2).unwrap_or(42)
    assert(y == 42)
