//! check-only

// Behavior test: backward pipeline operator <| (spec SS9.6)
// TODO: <| operator not yet implemented in the parser.
// This test will exercise backward pipeline once available.

fn main:
    let x = 42
    assert(x == 42)
