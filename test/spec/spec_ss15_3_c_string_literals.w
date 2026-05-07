//! skip: non-executable spec sketch for Section 15.3 — C-String Literals (formerly 25.84); contains pseudo-code for unimplemented feature work
// Spec test: Section 15.3 — C-String Literals (formerly 25.84)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: c"..." produces &CStr
fn test:
    let s: &CStr = c"hello"
    assert(s.len() == 5)           // "hello" without NUL
    puts(s.ptr)         // NUL is present in memory
