//! check-only

// Behavior test: error declarations (spec SS10.8, SS10.9)
// TODO: error declarations (error ParseError = ...) not yet implemented.
// TODO: error-from conversion (error MyErr from OtherErr) not yet implemented.

fn main:
    let x = 42
    assert(x == 42)
