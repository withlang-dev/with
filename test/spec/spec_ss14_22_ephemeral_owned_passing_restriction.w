//! skip: non-executable spec sketch for Section 14.22 — Ephemeral Owned Passing Restriction (formerly 25.77); contains pseudo-code for unimplemented feature work
// Spec test: Section 14.22 — Ephemeral Owned Passing Restriction (formerly 25.77)
// These are pseudo-code test cases from the specification.
// Remove the //! skip directive once the features are implemented.

// FAIL: ephemeral by-value to external function
fn store_globally(t: Task[i32]): ...  // separately compiled

fn test_fail:
    var x = 42
    let task = my_fn(&mut x)
    store_globally(task)                // ERROR: ephemeral value cannot be
                                        // passed as owned to external fn

// PASS: ephemeral by reference
fn inspect(t: &Task[i32]): ...

fn test:
    var x = 42
    let task = my_fn(&mut x)
    inspect(&task)                      // OK: passed by reference
