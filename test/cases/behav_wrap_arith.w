//! check-only

// Behavior test: wrapping arithmetic operators (spec SS4.2)
// TODO: +%, -%, *% wrapping operators not yet implemented in parser.
// Regular arithmetic operators work correctly.

fn main:
    assert(1 + 2 == 3)
    assert(10 - 3 == 7)
    assert(4 * 5 == 20)
