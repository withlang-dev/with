//! expect-error: a named rest '..name' binds only in a tuple pattern

// #1366: a variant payload list has no type to bind its rest as; `..name`
// there is an error, not a silently unbound name.
enum E:
    Three(i32, i32, i32)

fn main:
    let v = E.Three(1, 2, 3)
    match v:
        .Three(a, ..others) => print(f"{a}")
