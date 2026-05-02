// Spec test: Section 10.6 — Unwrap and Expect (formerly 25.48)

// PASS: .unwrap() on Some
fn test_unwrap_some:
    let x: Option[i32] = Some(42)
    assert(x.unwrap() == 42)

// PASS: .unwrap() on Ok
fn test_unwrap_ok:
    let r: Result[i32, str] = Ok(10)
    assert(r.unwrap() == 10)

// blocked: .expect() not implemented
// fn test_expect_some:
//     let x = Some("hello")
//     assert(x.expect("must have value") == "hello")

// blocked: panic tests need runtime panic test infrastructure
// fn test_unwrap_none_panics:
//     let x: Option[i32] = None
//     x.unwrap()    // PANICS

// fn test_expect_err_panics:
//     let r: Result[i32, str] = Err("bad")
//     r.expect("operation failed")    // PANICS
