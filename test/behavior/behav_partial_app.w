//! check-only

// Behavior test: partial application and placeholder closures (spec SS9.3, SS9.4)
// TODO: Partial application add(5, _) not yet implemented.
// TODO: Placeholder closures _.field, _.method(), _ + 1 not yet implemented.

fn apply(f: fn(i32) -> i32, x: i32) -> i32:
    f(x)

fn main:
    // Closures work as a manual alternative to partial application
    let add_five = x => x + 5
    assert(apply(add_five, 3) == 8)
