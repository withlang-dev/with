//! skip: non-executable spec sketch for Section 9.7 — Exhaustiveness (formerly 25.20); contains pseudo-code for unimplemented feature work
// Spec test: Section 9.7 — Exhaustiveness (formerly 25.20)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

enum Color { Red | Green | Blue }

// PASS
fn name(c: Color) -> str:
    match c:
        Red => "red"; Green => "green"; Blue => "blue"

// FAIL
fn name(c: Color) -> str:
    match c:
        Red => "red"; Green => "green"   // ERROR: missing Blue

// PASS: wildcard
fn name(c: Color) -> str:
    match c:
        Red => "red"; _ => "other"
