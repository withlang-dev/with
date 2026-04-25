//! skip
// Spec test: Section 10.6 — Unwrap and Expect (formerly 25.48)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: .unwrap() on Some
fn test:
    let x: Option[i32] = Some(42)
    assert(x.unwrap() == 42)

// PASS: .unwrap() on Ok
fn test:
    let r: Result[i32, str] = Ok(10)
    assert(r.unwrap() == 10)

// PASS: .expect() on Some
fn test:
    let x = Some("hello")
    assert(x.expect("must have value") == "hello")

// PASS (panics): .unwrap() on None
fn test_panics:
    let x: Option[i32] = None
    x.unwrap()    // PANICS: "called unwrap() on None"

// PASS (panics): .expect() on Err
fn test_panics:
    let r: Result[i32, str] = Err("bad")
    r.expect("operation failed")    // PANICS: "operation failed: bad"
