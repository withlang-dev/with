//! skip: non-executable spec sketch for Section 4.4, 18.2 — Enum Constructor Imports (formerly 25.26); contains pseudo-code for unimplemented feature work
// Spec test: Section 4.4, 18.2 — Enum Constructor Imports (formerly 25.26)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

enum Color { Red | Green | Blue }

// PASS: unqualified after import
use Color.{Red, Green, Blue}
fn test:
    let c = Red                // no prefix needed
    match c:
        Red   => "red"
        Green => "green"
        Blue  => "blue"

// PASS: Option/Result always unqualified (prelude)
fn test:
    let x: Option[i32] = Some(5)    // not Option.Some
    let y: Result[i32, str] = Ok(5)  // not Result.Ok
