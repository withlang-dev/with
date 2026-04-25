//! skip
// Spec test: Section 4.7 — Range Values (formerly 25.105)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

fn count(r: Range[i32]) -> i32:
    var total = 0
    for _ in r:
        total += 1
    total

fn test:
    let window = 0..4
    assert(count(window) == 4)
