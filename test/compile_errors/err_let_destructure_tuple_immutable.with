//! expect-error: cannot assign to immutable variable

// #1354: only `var` makes pattern bindings mutable; a `let` tuple destructure
// binds immutable names (§9.7).

fn main:
    let (x, y) = (1, 2)
    x = x + 10
    print(f"{x} {y}")
