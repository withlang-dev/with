//! skip
// Spec test: Section 3 — References and Second-Class Rule (formerly 25.2)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: reference as local
fn test:
    let x = 42
    let r = &x
    print(r)

// FAIL: reference in struct
type Bad { data: &i32 }        // ERROR

// FAIL: reference in container
fn test:
    let x = 42
    var v = Vec.new()
    v.push(&x)                   // ERROR

// PASS: non-escaping closure captures ref
fn test:
    let x = 42
    let r = &x
    vec![1, 2, 3].for_each(item => print(f"{item} {r}"))

// FAIL: escaping closure captures ref
fn test:
    let x = 42
    let r = &x
    thread.spawn_os(() => print(r))   // ERROR
