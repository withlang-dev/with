//! skip: non-executable spec sketch for Section 5 — Ephemeral Types (formerly 25.6); contains pseudo-code for unimplemented feature work
// Spec test: Section 5 — Ephemeral Types (formerly 25.6)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: ephemeral local
fn test:
    let v = "hello".as_view()
    print(v)

// FAIL: ephemeral in struct
type Bad { view: StrView }      // ERROR

// PASS: explicit ephemeral struct
type Ok = ephemeral { view: StrView }

// FAIL: ephemeral in container
fn test:
    let v = "hello".as_view()
    var vec = Vec.new()
    vec.push(Some(v))             // ERROR: Option[StrView] is ephemeral
