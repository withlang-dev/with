//! check-only

// Behavior test: advanced async features (spec SS14.6, SS14.9, SS14.10, SS14.13)
// TODO: async blocks, select await, async scope, scope |s| not yet implemented.
// This test will exercise those features once available.

fn main:
    let x = 42
    assert(x == 42)
