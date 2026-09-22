//! expect-error: written in place ([]mut)

// #1229: a literal is a temporary; writes through a `[]mut T` view of it are
// lost when the statement ends. Bind it (`var xs = [...]`) to keep them.
fn bump(values: []mut i32): values[0] = 9

fn main:
    bump([5, 6])
