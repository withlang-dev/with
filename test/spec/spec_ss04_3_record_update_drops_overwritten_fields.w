//! skip: non-executable spec sketch for Section 4.3 — Record Update Drops Overwritten Fields (formerly 25.85); contains pseudo-code for unimplemented feature work
// Spec test: Section 4.3 — Record Update Drops Overwritten Fields (formerly 25.85)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: overwritten fields are dropped, non-overwritten are moved
fn test:
    let p1 = NamedPoint { x: "first", y: "second" }
    let p2 = { p1 with x: "third" }
    // p1.x ("first") was dropped, p1.y ("second") was moved to p2.y
    assert(p2.x == "third")
    assert(p2.y == "second")
