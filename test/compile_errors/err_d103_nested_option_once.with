//! expect-check-fail: type mismatch

// §4.9a (D103): the conversion applies once, at the demand. A bare `3`
// offered where `Option[Option[i32]]` is demanded becomes
// `Some(3): Option[i32]`, which then mismatches: nesting is never guessed.
fn main:
    let nested: Option[Option[i32]] = 3
    print(nested.is_some())
