//! skip: non-executable spec sketch for Section 13.2 — Iter One-Implementation Rule (formerly 25.70); contains pseudo-code for unimplemented feature work
// Spec test: Section 13.2 — Iter One-Implementation Rule (formerly 25.70)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// FAIL: conflicting Iter implementations
type MyBuffer { data: Vec[u8] }
impl Iter[u8] for MyBuffer: ...
impl Iter[String] for MyBuffer: ...  // ERROR: MyBuffer already implements Iter[u8]

// PASS: named methods for alternate iteration
type MyBuffer { data: Vec[u8] }
impl Iter[u8] for MyBuffer: ...
extend MyBuffer:
    fn lines(self: &Self) -> LineIter: ...   // separate iterator type
