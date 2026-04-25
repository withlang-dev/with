//! skip
// Spec test: Section 3.4 — Disjoint Slice Operations (formerly 25.78)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: split_at_mut returns disjoint slices — compiler knows
fn test:
    var data = vec![1, 2, 3, 4, 5]
    let (left, right) = data.split_at_mut(3)
    left[0] = 10                        // OK: disjoint
    right[0] = 40                       // OK: no aliasing
