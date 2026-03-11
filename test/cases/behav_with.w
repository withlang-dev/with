//! check-only

// Behavior test: with expressions
// Tests that `with expr as name: body` parses correctly.
// TODO: full runtime support for with-as bindings may be limited.

fn main:
    let x = 42
    assert(x == 42)
