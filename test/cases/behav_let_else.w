//! check-only

// Behavior test: let...else (spec SS9.7)
// TODO: let Some(x) = expr else: fallback not yet implemented.
// See behav_let_else_runtime.w for if-let alternative that works.

fn main:
    let x = 42
    assert(x == 42)
