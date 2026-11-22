//! expect-error: non-exhaustive match

// Spec test: Section 9.7 — Exhaustiveness (negative case)
//
// §9.7: an expression-position match (its value is used/returned) must be
// exhaustive. A non-exhaustive match here is a compile error, not a warning.

enum Color:
    Red
    Green
    Blue

fn name(c: Color) -> str:
    match c:                 // expression position (the function's return value)
        .Red => "red"
        .Green => "green"
        // missing .Blue — must be a compile error

fn main:
    print(name(Color.Red))
