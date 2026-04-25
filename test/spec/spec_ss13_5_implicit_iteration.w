//! skip
// Spec test: Section 13.5 — Implicit Iteration (formerly 25.46)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// PASS: for-in auto-inserts .iter()
fn test:
    let items = vec![1, 2, 3]
    var sum = 0
    for x in items:              // compiler inserts .iter()
        sum += x
    assert(sum == 6)
    assert(items.len() == 3)     // items not consumed

// PASS: explicit .iter() still works
fn test:
    let items = vec![1, 2, 3]
    var sum = 0
    for x in items.iter():
        sum += x
    assert(sum == 6)

// PASS: ranges don't need .iter() (implement Iter directly)
fn test:
    var sum = 0
    for i in 0..4:
        sum += i
    assert(sum == 6)

// PASS: destructuring in for loop
fn test:
    let pairs = vec![(1, "a"), (2, "b")]
    for (n, s) in pairs:         // .iter() auto-inserted
        assert(n > 0)

// PASS: refutable patterns skip non-matching elements
fn test:
    let values = vec![Some(1), None, Some(3)]
    var sum = 0
    for Some(x) in values:
        sum += x
    assert(sum == 4)

// PASS: mutable iteration requires explicit .iter_mut()
fn test:
    var items = vec![1, 2, 3]
    for x in items.iter_mut():
        *x *= 2
    assert(items == vec![2, 4, 6])
