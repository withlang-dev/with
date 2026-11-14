//! expect-check-fail: no type argument is written on `parse` (§15.5): write `text as i32`, or let the demand name the type: `let n: i32 = text.parse()`

// §15.5 (D204): `parse` takes its type from the demand on its result.
fn main:
    let n = "42".parse[i32]()
