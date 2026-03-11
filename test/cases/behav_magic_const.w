//! check-only

// Behavior test: magic constants (spec SS17.0)
// TODO: __FILE__, __LINE__, __FN__ not yet implemented.
// These will be special identifiers replaced at compile time.

fn main:
    let x = 42
    assert(x == 42)
