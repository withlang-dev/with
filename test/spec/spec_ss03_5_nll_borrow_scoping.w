//! skip
// Spec test: Section 3.5 — NLL Borrow Scoping (formerly 25.4)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: borrow ends at last use
fn test:
    var x = 5
    let r = &x
    print(r)
    x = 10           // OK

// FAIL: mutation while borrow active
fn test:
    var x = 5
    let r = &x
    x = 10           // ERROR
    print(r)

// PASS: mutable then shared
fn test:
    var x = 5
    let r = &mut x
    *r = 10          // last use
    let s = &x       // OK
    print(s)
