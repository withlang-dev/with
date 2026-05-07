//! skip: non-executable spec sketch for Section 13.4 — No References Across Yield (formerly 25.65); contains pseudo-code for unimplemented feature work
// Spec test: Section 13.4 — No References Across Yield (formerly 25.65)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// FAIL: reference to local crosses yield
gen fn bad -> &str:
    let s = "hello".to_owned()
    let r = &s
    yield r                          // ERROR: borrow of `s` live across yield

// PASS: owned value across yield
gen fn ok -> str:
    let s = "hello".to_owned()
    yield s.clone()
    yield s
