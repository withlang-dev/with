//! skip
// Spec test: Section 10.5 — sequence / traverse / transpose (formerly 25.28)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: sequence on Vec[Option]
fn test:
    let xs: Vec[Option[i32]] = vec![Some(1), Some(2), Some(3)]
    assert(xs.sequence() == Some(vec![1, 2, 3]))

// PASS: sequence short-circuits on None
fn test:
    let xs: Vec[Option[i32]] = vec![Some(1), None, Some(3)]
    assert(xs.sequence() == None)

// PASS: sequence on Vec[Result]
fn test:
    let rs: Vec[Result[i32, str]] = vec![Ok(1), Ok(2)]
    assert(rs.sequence() == Ok(vec![1, 2]))

// PASS: traverse applies function: sequences
fn test:
    let strs = vec!["1", "2", "3"]
    let parsed = strs.traverse(s => s.parse_int())
    assert(parsed == Ok(vec![1, 2, 3]))

// PASS: traverse fails on first error
fn test:
    let strs = vec!["1", "bad", "3"]
    assert(strs.traverse(s => s.parse_int()).is_err())

// PASS: transpose Option[Result] → Result[Option]
fn test:
    let x: Option[Result[i32, str]] = Some(Ok(5))
    assert(x.transpose() == Ok(Some(5)))

    let y: Option[Result[i32, str]] = None
    assert(y.transpose() == Ok(None))

    let z: Option[Result[i32, str]] = Some(Err("bad"))
    assert(z.transpose() == Err("bad"))
