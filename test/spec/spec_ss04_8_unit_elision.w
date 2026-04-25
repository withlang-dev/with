//! skip
// Spec test: Section 4.8 — Unit Elision (formerly 25.45)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: Ok() with Unit elision
fn do_work -> Result[Unit, str]: Ok()
fn test:
    assert(do_work().is_ok())

// PASS: Ok(()) still works
fn do_work2 -> Result[Unit, str]: Ok(())
fn test:
    assert(do_work2().is_ok())

// PASS: unwrap_or with Unit elision
fn test:
    let r: Result[Unit, str] = Err("fail")
    r.unwrap_or()                   // desugars to .unwrap_or(())

// PASS: Unit elision in match
fn test:
    let r: Result[Unit, str] = Ok()
    match r:
        Ok() => assert(true)
        Err(_) => assert(false)

// PASS: no elision when T != Unit (Ok still requires argument)
fn test:
    let r: Result[i32, str] = Ok(42)   // 42 required, not Unit
    assert(r.unwrap_or(0) == 42)
