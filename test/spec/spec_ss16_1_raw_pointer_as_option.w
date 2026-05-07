//! skip: non-executable spec sketch for ) (Section 16.1 — Raw Pointer .as_option (formerly 25.97); contains pseudo-code for unimplemented feature work
// Spec test: ) (Section 16.1 — Raw Pointer .as_option (formerly 25.97)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: non-null pointer → Some
fn test:
    var x: i32 = 42
    let p: *mut i32 = &mut x
    assert(p.as_option().is_some())

// PASS: null pointer → None
fn test:
    let p: *mut i32 = null
    assert(p.as_option().is_none())

// PASS: as_option composes with ?? 
fn test:
    let p: *const i32 = null
    let val = p.as_option().map(p => unsafe { *p }).unwrap_or(0)
    assert(val == 0)
