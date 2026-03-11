//! check-only

// Behavior test: multiple with bindings (spec SS7.5)
// TODO: with a as x, b as y: (comma-separated bindings) not yet implemented.
// TODO: with Form 1 (guarded access via Scoped trait) needs sema support.

fn main:
    let x = 42
    assert(x == 42)
