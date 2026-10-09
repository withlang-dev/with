//! expect-error: a match guard cannot follow a pattern that takes elements out of an owned Vec yet (#2289)

// D115 (§9.7): a failed guard puts the arm's bindings back into the
// subject, and an element removed from an owned Vec has no way back yet.
fn mk() -> Vec[i32]: [1, 2]

fn main:
    match mk():
        [a, ..rest] if a > 0 => print(rest.len())
        _ => print("no")
