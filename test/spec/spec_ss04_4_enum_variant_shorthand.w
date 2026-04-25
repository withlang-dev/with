//! skip
// Spec test: Section 4.4 — Enum Variant Shorthand (formerly 25.35)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

enum Color { Red | Green | Blue }

// PASS: shorthand in return position
fn default_color -> Color: .Blue

// PASS: shorthand in match arms
fn describe(c: Color) -> str:
    match c:
        .Red   => "red"
        .Green => "green"
        .Blue  => "blue"

// PASS: shorthand in function arguments
fn paint(c: Color): ...
fn test:
    paint(.Red)

// PASS: shorthand in struct field
type Config { theme: Color }
fn test:
    let cfg = Config { theme: .Green }
    assert(describe(cfg.theme) == "green")

// FAIL: ambiguous shorthand
fn test:
    let x = .Red    // ERROR: cannot infer type for `.Red`
