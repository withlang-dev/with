//! skip: non-executable spec sketch for Section 13.6a — Option and Result For-Comprehensions (formerly 25.103); contains pseudo-code for unimplemented feature work
// Spec test: Section 13.6a — Option and Result For-Comprehensions (formerly 25.103)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: Option comprehension
fn test:
    let result = for a in Some(2); b in Some(3):
        yield a + b
    assert(result == Some(5))

// PASS: Option guard
fn test:
    let result = for x in Some(4); if x > 0:
        yield x * 2
    assert(result == Some(8))

// PASS: Result comprehension
fn test:
    let result: Result[i32, str] =
        for a in Ok(2); b in Ok(3):
        yield a + b
    assert(result == Ok(5))
