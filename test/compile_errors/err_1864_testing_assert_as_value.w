//! expect-error: `assert` is a compiler-known form, not a function

// D86 (§18.2, #1864): the std.testing forms are compiler-known forms too.
use std.testing

fn main:
    let f = testing.assert
    f(true, "message", "here")
