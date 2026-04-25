//! skip
// Spec test: Section 17.4 — Comptime Cascade (formerly 25.95)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: no comptime prefix needed inside comptime fn
comptime fn count_fields[T: type] -> usize:
    let mut n = 0
    for field in T.fields():       // cascade: no comptime prefix
        n += 1
    n

@[test]
fn test:
    assert(count_fields[Point]() == 2)

// PASS: type method syntax
comptime fn type_name[T: type] -> str: T.name()

@[test]
fn test:
    assert(type_name[i32]() == "i32")
