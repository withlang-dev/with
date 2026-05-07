//! skip: non-executable spec sketch for Section 9.6 — Function Composition (formerly 25.24); contains pseudo-code for unimplemented feature work
// Spec test: Section 9.6 — Function Composition (formerly 25.24)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: forward composition
fn double(x: i32) -> i32: x * 2
fn add1(x: i32) -> i32: x + 1
fn test:
    let f = double >> add1
    assert(f(5) == 11)       // add1(double(5)) = 11

// PASS: backward composition
fn test:
    let f = add1 << double
    assert(f(5) == 11)       // add1(double(5)) = 11

// PASS: composition with map
fn test:
    let process = trim >> lowercase
    let result = names |> map(process) |> collect[Vec]()
